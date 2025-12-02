/*
See LICENSE folder for this sample’s licensing information.

Abstract:
When the app is started to continue a user activity, the app will show the
 location detail of the activity as well as making that location current.
*/

import MapKit
import os.log
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    /// - Tag: continue_activity
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        guard userActivity.activityType == "com.example.apple-samplecode.ProactiveToolbox.view-location",
            let tabBarController = window?.rootViewController as? UITabBarController,
            let navigationController = tabBarController.viewControllers?.first as? UINavigationController
            else { return false }
        
        tabBarController.selectedIndex = 0
        
        /*
         Calling the restoration handler is optional and is only needed
         when specific objects are capable of continuing the activity.
         */
        restorationHandler(navigationController.viewControllers)
        
        return true
    }
}
