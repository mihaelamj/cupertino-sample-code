/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate is responsible for handling actions performed in the Top Shelf.
*/

import UIKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        os_log("Will open URL from Top Shelf. URL=%@", url as NSURL)
        return true
    }
}
