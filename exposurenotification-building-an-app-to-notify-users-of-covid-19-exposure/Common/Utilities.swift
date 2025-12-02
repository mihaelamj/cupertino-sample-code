/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Exposure Notification-related utility methods.
*/

import UIKit

func showError(_ error: Error, from viewController: UIViewController) {
    let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Title"), message: error.localizedDescription, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Button"), style: .cancel))
    viewController.present(alert, animated: true, completion: nil)
}

@available(iOS 13.0, *)
func openSettings(from viewController: UIViewController) {
    viewController.view.window?.windowScene?.open(URL(string: UIApplication.openSettingsURLString)!, options: nil, completionHandler: nil)
}

func ENManagerIsAvailable() -> Bool {
    return NSClassFromString("ENManager") != nil
}

enum SupportedENAPIVersion {
    case version2
    case version1
    case unsupported
}

func getSupportedExposureNotificationsVersion() -> SupportedENAPIVersion {
    if #available(iOS 13.7, *) {
        return .version2
    } else if #available(iOS 13.5, *) {
        return .version1
    } else if ENManagerIsAvailable() {
        return .version2
    } else {
        return .unsupported
    }
}
