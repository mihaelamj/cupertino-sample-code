/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class for capturing and storing photos.
*/

import AVFoundation
import Photos
import UIKit.UIImage

/// Captures photos using the AV Capture Photo Output method.
class PhotoCapturer: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {

    let photoOutput = AVCapturePhotoOutput()

    @MainActor var onPhotoCompletion: ((UIImage) -> Void)?

    /// Initiates a photo capture from the a camera input.
    ///
    /// The delegate handles lifecycle reuslts and callbacks.
    public func capture() {

        let avCodec: AVVideoCodecType = .jpeg
        guard photoOutput.availablePhotoCodecTypes.contains(avCodec) else {
            print("\'\(avCodec.rawValue)\' codec is not available for this output")
            return
        }

        print("capturing photo")
        let captureSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: avCodec])
        photoOutput.capturePhoto(with: captureSettings, delegate: self)
    }

    /// Saves a captured photo to the person's photo library.
    public func writeToPhotoLibrary(_ photo: AVCapturePhoto) async {
        guard await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized else {
            print("photo library write access denied")
            return
        }
        guard let photoData = photo.fileDataRepresentation() else {
            print("photo file data representation is nil")
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let options = PHAssetResourceCreationOptions()
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: photoData, options: options)
            }
            print("saved photo to library")
        } catch let error {
            print("failed to write photo to photo library: \(String(describing: error))")
        }
    }

    /// Converts a captured photo to an image with the correct orientation.
    private func makeUIImage(from photo: AVCapturePhoto) -> UIImage? {
        guard let cgImage = photo.cgImageRepresentation(),
              let rawValue = photo.metadata[kCGImagePropertyOrientation as String] as? UInt32,
              let cgOrientation = CGImagePropertyOrientation(rawValue: rawValue) else {
            return nil
        }
        let orientation = UIImage.Orientation(cgOrientation)
        return UIImage(cgImage: cgImage, scale: 1, orientation: orientation)
    }

    // MARK: AVCapturePhotoCaptureDelegate

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            print("did finish processing photo error: \(String(describing: error))")
        } else {
            print("did finish processing photo")
            Task {
                if let image = makeUIImage(from: photo) {
                    await onPhotoCompletion?(image)
                }
                await writeToPhotoLibrary(photo)
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error {
            print("[\(resolvedSettings.uniqueID)] did finish photo capture with error: \(String(describing: error))")
        } else {
            print("[\(resolvedSettings.uniqueID)] did finish photo capture")
        }
    }
}

extension UIImage.Orientation {

    init(_ cgOrientation: CGImagePropertyOrientation) {
        switch cgOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        }
    }
}
