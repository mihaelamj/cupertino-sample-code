/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model that contains the configuration and image segments.
*/

import Foundation
import SwiftUI
import PhotosUI
import CoreML

@MainActor
final class ViewModel: ObservableObject {
    typealias Model = DETRResnet50SemanticSegmentationF16P8
    typealias ModelOutput = DETRResnet50SemanticSegmentationF16P8Output

    /// The original image.
    @Published private(set) var image: Image?

    /// The overlay image that masks a selected label.
    @Published private(set) var maskedImage: Image?

    /// A list of predicted labels in the original image.
    @Published private(set) var predictedLabels: [String] = []

    /// A potential error message to communicate to the user.
    @Published private(set) var errorMessage: String?

    /// A Boolean value that indicates whether to show an image picker widget.
    @Published var showPhotoPicker = false

    /// The selected photo that the image picker shows.
    @Published var selectedPhoto: PhotosPickerItem? = nil {
        didSet {
            selectedPhoto?.loadTransferable(type: Data.self) { [weak self] result in
                Task { @MainActor in
                    self?.handleSelectedPhotoTransferable(result)
                }
            }
        }
    }

    @Published private(set) var isModelLoaded = false

    private var masks = [String: Image]()

    /// The processed input image that helps restore the geometry of mask images.
    private var inputImage: UIImage?

    /// A set of the possible labels in the metadata.
    private var labelNames: [String] = []

    /// The result array of the model.
    private var resultArray: MLShapedArray<Int32>?

    /// The model.
    private var model: Model?

    /// Loads the semantic segmentation model.
    nonisolated func loadModel() async {
        do {
            let model = try Model()
            let labels = model.model.segmentationLabels
            await didLoadModel(model, labels: labels)
        } catch {
            Task { @MainActor in
                errorMessage = "The model failed to load: \(error.localizedDescription)"
            }
        }
    }

    /// A string value for the selected label.
    @Published var selectedLabel: String? = nil {
        didSet {
            guard let selectedLabel else {
                maskedImage = nil
                return
            }
            do {
                maskedImage = try maskedImageForLabel(selectedLabel)
            } catch {
                maskedImage = nil
                errorMessage = "Failed to render mask: \(error.localizedDescription)"
            }
        }
    }

    func selectLabel(at normalizedPosition: CGPoint) {
        selectedLabel = predictedLabel(at: normalizedPosition)
    }
}

// MARK: - Private

@MainActor
private extension ViewModel {
    var targetSize: CGSize { .init(width: 448, height: 448) }

    func didLoadModel(_ model: Model, labels: [String]) async {
        self.labelNames = labels
        self.model = model

        isModelLoaded = true

        guard self.image != nil else {
            return
        }

        // Perform inference on a pending image.
        performInferenceAndUpdateUI()
    }

    func handleSelectedPhotoTransferable(_ result: Result<Data?, any Error>) {
        image = nil
        maskedImage = nil
        masks = [:]

        switch result {
        case .success(let data?):
            if let uiImage = UIImage(data: data) {
                handleSelectedImage(uiImage)
            }

        case .success(nil):
            errorMessage = "Empty image"

        case .failure(let err):
            errorMessage = "Failed to load image: \(err)"
        }
    }

    func handleSelectedImage(_ uiImage: UIImage) {
        self.inputImage = uiImage
        self.image = Image(uiImage: uiImage)
        self.maskedImage = nil
        self.errorMessage = nil
        masks = [:]

        performInferenceAndUpdateUI()
    }

    func performInferenceAndUpdateUI() {
        Task { @MainActor in
            do {
                let predictionResult = try await performInference()
                try handlePredictionResult(predictionResult)

            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func handlePredictionResult(_ predictionResult: ModelOutput) throws {
        // Reset the selection.
        self.selectedLabel = nil
        self.masks = [:]

        // Store the new result.
        let resultArray = predictionResult.semanticPredictionsShapedArray
        self.resultArray = resultArray

        // Get the unique label indices.
        let uniqueLabelIndices = resultArray.uniqueValues

        // Map the label indices to label names.
        self.predictedLabels = uniqueLabelIndices.map({ labelNames[Int($0)] })
    }

    /// Performs inference on the image-segmentation model.
    nonisolated func performInference() async throws -> ModelOutput {
        guard let model = await self.model else {
            throw ViewModelError.modelNotLoaded
        }
        guard let inputImage = await self.inputImage else {
            throw ViewModelError.noInputImage
        }

        let context = CIContext()
        let resizedImage = await CIImage(cgImage: inputImage.cgImage!).resized(to: targetSize)
        let pixelBuffer = context.render(resizedImage, pixelFormat: kCVPixelFormatType_32ARGB)

        guard let pixelBuffer else {
            throw ViewModelError.fileFormatNotSupported
        }

        return try model.prediction(image: pixelBuffer)
    }

    func maskedImageForLabel(_ selectedLabel: String) throws -> Image? {
        if let cachedMask = masks[selectedLabel] {
            return cachedMask
        }

        guard let cgImage = try renderMask() else {
            return nil
        }
        let uiImage = UIImage(
            cgImage: cgImage,
            scale: inputImage!.scale,
            orientation: inputImage!.imageOrientation
        )
        let image = Image(uiImage: uiImage)
        masks[selectedLabel] = image
        return image
    }

    func renderMask() throws -> CGImage? {
        guard let resultArray else {
            return nil
        }

        // Convert the results to a mask.
        var bitmap = resultArray.scalars.map { labelIndex in
            let label = self.labelNames[Int(labelIndex)]
            if label == selectedLabel {
                return 0xFFFFFFFF as UInt32 // 0xFFFFFF00 as UInt32
            } else {
                return 0x20202080 as UInt32 // 0x00000000 as UInt32
            }
        }

        // Convert the mask to an image.
        let width = resultArray.shape[1]
        let height = resultArray.shape[0]
        let image = bitmap.withUnsafeMutableBytes { bytes in
            let context = CGContext(
                data: bytes.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 4 * width,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipLast.rawValue  // RGB0
            )
            return context?.makeImage()
        }

        return image!
    }

    func predictedLabel(at normalizedPosition: CGPoint) -> String? {
        guard
            let resultArray,
            normalizedPosition.x <= 1,
            normalizedPosition.y <= 1,
            normalizedPosition.x >= 0,
            normalizedPosition.y >= 0
        else {
            return nil
        }

        let col = Int((normalizedPosition.x * CGFloat(resultArray.shape[0] - 1)).rounded())
        let row = Int((normalizedPosition.y * CGFloat(resultArray.shape[1] - 1)).rounded())
        let labelIndex = resultArray[scalarAt: row, col]
        return labelNames[Int(labelIndex)]
    }
}

/// A representation of the errors that the view model throws and catches.
private enum ViewModelError: Int, Error {
    case modelNotLoaded = 1
    case noInputImage
    case fileFormatNotSupported

    var localizedDescription: String? {
        switch self {
        case .modelNotLoaded:
            "Model not loaded."
        case .noInputImage:
            "No input image."
        case .fileFormatNotSupported:
            "File format isn't supported."
        }
    }
}
