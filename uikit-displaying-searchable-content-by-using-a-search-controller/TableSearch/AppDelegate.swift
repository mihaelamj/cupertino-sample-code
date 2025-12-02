/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate class used for setting up our data model and state restoration.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // The app delegate must implement the window from UIApplicationDelegate protocol to use a main storyboard file.
    var window: UIWindow?
    
    // MARK: - Application Life Cycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: - UIStateRestoration

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    @available(iOS 13.2, *)
    func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    @available(iOS 13.2, *)
    func application(_ application: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
        return true
    }
}
