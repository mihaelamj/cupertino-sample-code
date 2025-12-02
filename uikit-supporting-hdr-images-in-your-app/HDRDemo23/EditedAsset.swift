/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The representation of an image that the system edits using filters.
*/

import Foundation
import SwiftUI
import CoreImage
import CoreGraphics
import Combine
import UniformTypeIdentifiers
import Photos
import Observation

@MainActor
@Observable
class EditedAsset: FileDocument {

    nonisolated
    static var readableContentTypes: [UTType] { [.image] }
    
    nonisolated
    static var writableContentTypes: [UTType] { [.heic, .png] }

    let renderer: Renderer
    let asset: Asset
    let editingInput: PHContentEditingInput?
    let inputImage: CIImage?
    var outputType = UTType.heic
    var lastApply: ContinuousClock.Instant? = nil
    
    func apply() {
        if let lastApply {
            guard lastApply.duration(to: .now) >= .seconds(0.025) else { return }
        }
        lastApply = .now
        Task {
            await applyAdjustments(adjustments, showOriginal: showOriginal)
        }
    }

    // Workaround for a known issue with the `@Observable` macro.
    // For more information, see the iOS 17 Release Notes and the
    // macOS 14 Release Notes. (109722876)
    @ObservationIgnored
    var adjustmentsInternal: [Adjustment] = []

    var adjustments: [Adjustment] {
        get {
            access(keyPath: \.adjustments)
            return adjustmentsInternal
        }
        set {
            withMutation(keyPath: \.adjustments) {
                adjustmentsInternal = newValue
            }
            apply()
        }
    }

    @ObservationIgnored
    var showOriginalInternal = false

    var showOriginal: Bool {
        get {
            access(keyPath: \.showOriginal)
            return showOriginalInternal
        }
        set {
            withMutation(keyPath: \.showOriginal) {
                showOriginalInternal = newValue
            }
            apply()
        }
    }

    var pixelBuffer: CVPixelBuffer? = nil

    // If the asset is from a file, use the original filename as the default when saving.
    var defaultFilename: String? {
        return self.asset.file?.deletingPathExtension().lastPathComponent
    }

    func setPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        self.pixelBuffer = pixelBuffer
    }

    // Rerender the image to a CVPixelBuffer any time an adjustment changes,
    // or when the showOriginal toggle switches.
    func applyAdjustments(_ adjustments: [Adjustment], showOriginal: Bool) async {
        var image = inputImage
        if !showOriginal {
            for adjustment in adjustments {
                image = adjustment.apply(to: image)
            }
        }
        if let image {
            if let pixelBuffer = await renderer.render(image, destinationColorspace: inputImage?.colorSpace) {
                setPixelBuffer(pixelBuffer)
            }
        }
    }

    init(asset: Asset, renderer: Renderer, input: PHContentEditingInput? = nil) {

        self.asset = asset
        self.renderer = renderer
        self.editingInput = input

        var inputImage: CIImage?
        var adjustments: [Adjustment]?

        let ciOptions: [CIImageOption: Any] = [.applyOrientationProperty: true, .expandToHDR: true]

        if let input = input,
           let url = input.fullSizeImageURL {
            inputImage = CIImage(contentsOf: url, options: ciOptions)
            if let adjustmentData = input.adjustmentData {
                adjustments = Adjustment.load(from: adjustmentData)
            }
        } else if let url = asset.file {
            inputImage = CIImage(contentsOf: url, options: ciOptions)
        } else if let data = asset.data {
            inputImage = CIImage(data: data, options: ciOptions)
        } else {
            inputImage = nil
        }

        self.inputImage = inputImage
        self.adjustments = adjustments ?? Adjustment.defaultAdjustments

    }

    var editingOutput: PHContentEditingOutput? {
        guard let input = self.editingInput else {
            return nil
        }
        let output = PHContentEditingOutput(contentEditingInput: input)
        output.adjustmentData = Adjustment.save(adjustments)
        // Ask for a HEIC file to render as 10-bit HDR.
        guard let outputURL = try? output.renderedContentURL(for: .heic) else {
            print("Failed to obtain HEIC output URL.")
            return nil
        }
        guard export(to: outputURL) else {
            print("Failed to export image")
            return nil
        }
        return output
    }

    func applyFilters() -> CIImage? {
        var image = self.inputImage
        for adjustment in adjustments {
            image = adjustment.apply(to: image)
        }
        return image
    }

    func export(to file: URL) -> Bool {
        print("Exporting image to: \(file.path)")
        guard let outputImage = applyFilters() else {
            print("Failed to generate output image.")
            return false
        }
        return renderer.export(outputImage, to: file, type: nil, colorspace: inputImage?.colorSpace)
    }

    // The default FileDocument init isn't necessary. It's here only because the FileDocument protocol requires it.
    nonisolated
    required init(configuration: ReadConfiguration) throws {
        throw CocoaError(.featureUnsupported)
    }

    nonisolated
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try MainActor.assumeIsolated {
            guard let image = self.applyFilters() else {
                throw CocoaError(.fileWriteUnknown)
            }
            guard let data = self.renderer.export(image,
                                                  contentType: outputType,
                                                  colorspace: inputImage?.colorSpace) else {
                throw CocoaError(.fileWriteUnknown)
            }
            let fileWrapper = FileWrapper(regularFileWithContents: data)
            return fileWrapper
        }
    }
}
