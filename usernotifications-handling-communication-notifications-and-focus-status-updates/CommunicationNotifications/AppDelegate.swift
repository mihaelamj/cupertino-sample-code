/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The delegate that manages registering for remote notifications.
*/

import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Register for remote notifications.
        application.registerForRemoteNotifications()
        return true
    }
    
    /// Supported on physical devices only.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let hexadecimalString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Did register for remote notifications with token: \(hexadecimalString)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
    }
}
