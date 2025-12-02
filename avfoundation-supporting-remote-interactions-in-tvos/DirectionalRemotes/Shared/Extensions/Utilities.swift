/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities that deal with notifications and colors.
*/

import AVKit

extension Notification.Name {
    /// The notification name for a guide button press.
    static let guideButtonPressed = Notification.Name("guideButtonPressed")

    /// The notification name for an app background event.
    static let applicationDidEnterBackgroundNotification = Notification.Name("applicationDidEnterBackgroundNotification")
    /// The notification name for an app foreground event.
    static let applicationWillEnterForegroundNotification = Notification.Name("applicationWillEnterForegroundNotification")
}

extension UIColor {

    // Background colors.

    static var highlightedBackgroundColor: UIColor {
        UIColor(red: 24 / 255, green: 140 / 255, blue: 231 / 255, alpha: 1.0)
    }

    static var secondaryBackgroundColor: UIColor {
        .white
    }

    // Label colors.

    static var highlightedLabelColor: UIColor {
        .white
    }

    static var primaryLabelColor: UIColor {
        UIColor(red: 24 / 255, green: 140 / 255, blue: 231 / 255, alpha: 1.0)
    }

    static var secondaryLabelColor: UIColor {
        UIColor(white: 120 / 255, alpha: 1.0)
    }
}
