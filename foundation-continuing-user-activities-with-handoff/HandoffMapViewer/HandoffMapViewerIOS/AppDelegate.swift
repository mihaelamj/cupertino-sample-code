/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An AppDelegate implementation that receives the NSUserActivity for Handoff.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    // When Handoff launches the app, get the window's content view controller and pass it to
    // the resorationHandler. This results in the view controller receiving the activity in restoreUserActivityState(_:).
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let topNav = application.keyWindow?.rootViewController as? UINavigationController,
            let mapVC = topNav.viewControllers.first as? MapViewController else {
            return false
        }
        
        mapVC.loadView()
        restorationHandler([mapVC])
        return true
    }

}
