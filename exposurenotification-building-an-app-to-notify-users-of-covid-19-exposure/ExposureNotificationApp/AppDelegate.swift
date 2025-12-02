/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import ExposureNotification
import BackgroundTasks
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
    
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let tabBarController = scene.windows.first?.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = 0
        }
    }
}
