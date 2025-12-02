/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate class of the iOS app.
*/

import UIKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private lazy var sessionDelegator: SessionDelegator = {
        return SessionDelegator()
    }()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Trigger WCSession activation at the early phase of app launching.
        //
        assert(WCSession.isSupported(), "This sample requires Watch Connectivity support!")
        WCSession.default.delegate = sessionDelegator
        WCSession.default.activate()
        return true
    }
}
