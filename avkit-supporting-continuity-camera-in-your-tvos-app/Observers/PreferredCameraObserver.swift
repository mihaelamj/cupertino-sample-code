/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observation that monitors notifications from Notification Center that are
 specific to `AVCaptureDevice` instances.
*/

import AVFoundation

/// A class that observers a type property that indicates which camera the
/// system prefers.
///
/// Each instance observes the `.systemPreferredCamera` type property of the
/// `AVCaptureDevice` class.
class PreferredCameraObserver: NSObject {

    /// The key path for the camera the system recommends to the app.
    private static let cameraPropertyPath = "systemPreferredCamera"

    /// An alias that represents the signature of a callback handler closure.
    typealias NewCameraClosure = (_ camera: AVCaptureDevice) -> Void

    /// A closure the observer calls when the property changes.
    var handler: NewCameraClosure? = nil

    /// Registers for change notifications from the property that stores
    /// the system's preferred camera.
    /// - Parameter handler: A closure the observer calls when the property changes.
    override init() {
        super.init()

        AVCaptureDevice.addObserver(self,
                                    forKeyPath: Self.cameraPropertyPath,
                                    options: [.new],
                                    context: nil)
    }

    /// Removes the app's registration for change notifications from the property
    /// that stores the system's preferred camera.
    deinit {
        AVCaptureDevice.removeObserver(self, forKeyPath: Self.cameraPropertyPath)
    }

    /// Observes changes to the system's preferred camera and invokes the
    /// handler optional.
    ///
    /// - Parameters:
    ///   - keyPath: The path to the property that changed.
    ///   - object: The object with the property.
    ///   - change: A dictionary of information about the change.
    ///   - context: Additional context, if applicable.
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {

        // Confirms that the key path is the correct one.
        guard keyPath == Self.cameraPropertyPath else {
            // Sends all other key path observations to the superclass.
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }

        // Casts the new value as a capture device.
        guard let newCamera = change?[.newKey] as? AVCaptureDevice else {
            print("AVCaptureDevice's new preferred camera property value is nil.")
            return
        }

        handler?(newCamera)
    }
}
