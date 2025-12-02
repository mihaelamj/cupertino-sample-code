/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Capture manager extensions related to KVO and notifications.
*/

import AVFoundation

extension CaptureManager {

    /// Updates all the observers to monitor a new camera instance.
    /// - Parameter camera: A capture device that represents a camera.
    func observeCamera(_ camera: AVCaptureDevice) {
        // Tells the observer to watch the new camera's properties.
        videoEffectsObvserver.observeCamera(camera)

        // Tells the notification observer to monitor camera-related events.
        notificationObserver.observeCamera(camera,
                                           with: notification(_:for:))
    }
}

extension CaptureManager {

    /// An array of notifications the app listens to for a camera.
    static let notificationList: [Notification.Name] = [
        // A/V Capture device notifications.
        .AVCaptureDeviceWasDisconnected,

        // A/V Capture session notifications.
        .AVCaptureSessionDidStartRunning,
        .AVCaptureSessionDidStopRunning,
        .AVCaptureSessionWasInterrupted,
        .AVCaptureSessionInterruptionEnded,
        .AVCaptureSessionRuntimeError
    ]

    static func makeNotificationObserver() -> CaptureDeviceNotificationObserver {
        return CaptureDeviceNotificationObserver(notificationList)
    }

    /// A callback handler the camera notification obvserver calls each time it
    /// receives an event.
    /// - Parameters:
    ///   - notification: The name of the noficiation from Notification Center.
    ///   - camera: The camera the notification is for.
    /// - Tag: captureManager.notification
    func notification(_ notification: Notification, for camera: AVCaptureDevice) {
        print("Received notification: \(notification.name) for camera: \(camera)")

        // Only proceeds if this is a disconnection notififcation.
        guard notification.name == .AVCaptureDeviceWasDisconnected else { return }
        guard let device = notification.object as? AVCaptureDevice else { return }
        guard cameraIsNew(device) else { return }

        // Removes the disconnected device as the capture session's current input.
        DispatchQueue.main.async {
            self.activeInput = nil
        }
    }
}
