/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate that manages the application life cycle.
*/

import UIKit
import AVFoundation

@UIApplicationMain
class TVAppDelegate: UIResponder, UIApplicationDelegate {

    // A direct reference to this app delegate.

    static private(set) var shared: TVAppDelegate!
    
    // A direct reference to the app's window.
    
    var window: UIWindow?
    
    // Initial setup when the app has finished launching.
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        TVAppDelegate.shared = self
        
        // Create the data model.
        
        ConfigModel.shared = ConfigModel(nowPlayableBehavior: TVNowPlayableBehavior())
        
        return true
    }
}

