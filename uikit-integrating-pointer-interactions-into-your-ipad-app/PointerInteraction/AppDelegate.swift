/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
UIAppicationDelegate for this sample code project.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // The app delegate must implement the window from UIApplicationDelegate protocol to use a main storyboard file.
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
}
