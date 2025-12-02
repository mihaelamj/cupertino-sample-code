/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The portion of the `CaptureManager` type that supports Continuity Camera feature.
*/

import AVFoundation

extension CaptureManager {

    /// Returns a Boolean value that indicates whether the method successfully
    /// activates the system's default continuity camera.
    ///
    /// The method retrieves the system's default continuity camera device and
    /// selects it for the capture session's camera input.
    public func activateDefaultContinuityCameraDevice() -> Bool {
        let continuityCamera = AVCaptureDevice.default(.continuityCamera,
                                                       for: .video,
                                                       position: .unspecified)
        guard let continuityCamera else {
            print("Capture manager couldn't find a default continuity camera.")
            return false
        }

        let name = continuityCamera.localizedName

        guard setActiveVideoInput(continuityCamera) else {
            print("Capture manager couldn't activate the default continuity camera.")
            return false
        }

        print("Activating default continuity camera device: \(name)")
        return true
    }
}
