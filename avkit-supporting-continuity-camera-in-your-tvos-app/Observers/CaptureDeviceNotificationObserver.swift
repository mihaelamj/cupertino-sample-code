/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observation that monitors notifications from Notification Center that are
 specific to `AVCaptureDevice` instances.
*/

import AVFoundation

/// A structure that monitors notifications for one capture device instance at a time.
/// - Tag: CaptureDeviceNotificationObserver
struct CaptureDeviceNotificationObserver {
    /// A list of notifications the observer registers for.
    let notifications: [Notification.Name]

    /// The camera for which the observer is listening to notifications.
    private var camera: AVCaptureDevice?

    /// The main initializer that configures what notifications to listen for.
    /// - Parameter notificationList: An array of notification names.
    init(_ notificationList: [Notification.Name]) {
        notifications = notificationList
    }

    /// An alias that represents the signature of a callback handler closure.
    typealias NotificationClosure = (_: Notification,
                                     _ camera: AVCaptureDevice) -> Void

    /// Changes the camera the observer monitors.
    /// - Parameters:
    ///   - camera: A capture device instance that represents the new camera.
    ///   - handler: A closure the observer calls when it receives a notification.
    mutating func observeCamera(_ newCamera: AVCaptureDevice,
                                with handler: @escaping NotificationClosure) {

        // Exits early if it's the same instance the observer is currently watching.
        guard newCamera != self.camera else { return }

        let notificationCenter = NotificationCenter.default

        for notificationName in notifications {
            // Clears observations for the previous camera, if applicable.
            if let oldCamera = self.camera {
                notificationCenter.removeObserver(self,
                                                  name: notificationName,
                                                  object: oldCamera)
            }

            // Registers for the notification with the new camera.
            notificationCenter.addObserver(forName: notificationName,
                                           object: newCamera,
                                           queue: nil) { notification in

                // Invokes the caller's handler.
                handler(notification, newCamera)
            }
        }

        // Saves the camera to remove observations the next time.
        camera = newCamera
    }
}
