/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate.
*/

import UIKit
import TVServices
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        // Check for the guide button press.
        if userActivity.activityType == TVUserActivityTypeBrowsingChannelGuide {
            NotificationCenter.default.post(name: .guideButtonPressed, object: nil)
            return true
        }

        return false
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
        } catch {
            print("Setting AVAudioSession category failed.")
        }

        return true
    }

    // MARK: App lifecycle events

    func applicationDidEnterBackground(_ application: UIApplication) {
        NotificationCenter.default.post(name: .applicationDidEnterBackgroundNotification, object: nil)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: .applicationWillEnterForegroundNotification, object: nil)
    }

}
