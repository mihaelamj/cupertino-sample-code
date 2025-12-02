/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides the custom camera functionality.
*/

import AVFoundation
import SwiftUI

@Observable
class Camera: NSObject, AVCapturePhotoCaptureDelegate {
    var session = AVCaptureSession()
    var preview = AVCaptureVideoPreviewLayer()
    var output = AVCapturePhotoOutput()

    var photoData: Data? = nil
    var hasPhoto: Bool = false

    /// A function that returns a Boolean value if the app has access to use the camera — `true` if the user grants access, and `false`, if not.
    func checkCameraAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            let status = await AVCaptureDevice.requestAccess(for: .video)
            return status
        case .denied:
            return false
        case .restricted:
            return false
        @unknown default:
            return false
        }
    }

    /// Set up the capture session.
    func setup() -> Bool {
        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(for: .video) else {
            return false
        }

        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else {
            print("Unable to obtain video input.")
            return false
        }

        /// Check whether the session can add input.
        guard session.canAddInput(deviceInput) else {
            print("Unable to add device input to the capture session.")
            return false
        }

        /// Check whether the session can add output.
        guard session.canAddOutput(output) else {
            print("Unable to add photo output to the capture session.")
            return false
        }

        /// Add the input and output to the session.
        session.addInput(deviceInput)
        session.addOutput(output)
        session.sessionPreset = .photo

        session.commitConfiguration()

        /// Start running the capture session on a background thread.
        Task(priority: .background) {
            session.startRunning()
        }
        
        return true
    }

    func capturePhoto() {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    func retakePhoto() {
        /// Reset both the `photoData` and `hasPhoto` variables to allow photo recapture.
        photoData = nil
        hasPhoto = false

        Task(priority: .background) {
            session.startRunning()
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        photoData = photo.fileDataRepresentation()
        hasPhoto = true

        session.stopRunning()
    }
}
