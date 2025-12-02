/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate that manages the application life cycle.
*/

import UIKit
import AVFoundation

@UIApplicationMain
class IOSAppDelegate: UIResponder, UIApplicationDelegate {
    
    // A direct reference to this app delegate.
    
    static private(set) var shared: IOSAppDelegate!
    
    // A direct reference to the app's window.
    
    var window: UIWindow?
    
    // Initial setup when the app has finished launching.
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        IOSAppDelegate.shared = self
        
        // Create the data model.
        
        ConfigModel.shared = ConfigModel(nowPlayableBehavior: IOSNowPlayableBehavior())
        
        // Notify the UI that the model has been changed.
        
        guard let viewController = window?.rootViewController as? IOSConfigViewController
            else { fatalError("Root view controller must be an IOSConfigViewController") }
        
        viewController.updateConfig()
        
        return true
    }
}

