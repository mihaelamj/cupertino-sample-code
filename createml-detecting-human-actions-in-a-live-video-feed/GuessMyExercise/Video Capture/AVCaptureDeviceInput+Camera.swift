/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Creates and configures a camera device input for VideoCapture.swift.
*/

import AVFoundation

extension AVCaptureDeviceInput {
    /// Creates a camera input set at the configuration's frame rate.
    static func createCameraInput(position: AVCaptureDevice.Position) -> AVCaptureDeviceInput? {
        // Select the camera.
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: AVMediaType.video,
                                                   position: position) else {
            return nil
        }

        // Create an input from the camera.
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)

            // Device input is ready.
            return cameraInput
        } catch {
            print("Unable to create an input from the camera: \(error)")
            return nil
        }
    }
}
