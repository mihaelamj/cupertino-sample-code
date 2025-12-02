/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Application Delegate
*/

import UIKit
import ExposureNotification
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    ///  iOS 13 and later use the `window` property from the scene delegate, but this is needed for the
    ///  storyboard to function correctly on iOS 12.5.
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        return true
    }
}
