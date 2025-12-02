/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model for image selection from the Photo Picker and related views.
*/

import Foundation
import PhotosUI
import CoreTransferable
import SwiftUI

class PhotoSelectionModel: ObservableObject {

    enum ImageState {
        case noneselected
        case loading(Progress)
        case success(Image)
        case failure(Error)
    }

    enum TransferError: Error {
        case importFailed
    }
    
    struct SelectedImage: Transferable {
        let image: UIImage

        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                return SelectedImage(image: uiImage)
            }
        }
    }

    private(set) var imageState: ImageState = .noneselected
    @Published var image: CIImage? = nil
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .noneselected
            }
        }
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: SelectedImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let image?):
                    self.imageState = .success(Image(uiImage: image.image))
                    let ciImage = CIImage(image: image.image)
                    self.image = ciImage?.oriented(CGImagePropertyOrientation(image.image.imageOrientation))
                case .success(nil):
                    self.imageState = .noneselected
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
}

// Converts the image orientation to orientation of the device.
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        default: self = .up
        }
    }
}
