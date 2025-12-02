/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file defines the AppDelegate subclass of UIApplicationDelegate.
*/

 import UIKit

 @UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate {

 var window: UIWindow?

 func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
     self.window?.makeKeyAndVisible()

     return true
     }
 }
