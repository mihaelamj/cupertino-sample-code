/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate.
*/

import UIKit
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        /**
         This sample app has several configurable settings. This code provides the default value for the settings, which
         are in `application(_:willFinishLaunchingWithOptions:)` because the app needs to set
         default values before the app fully launches.
         */
        let defaultPreferences: [String: Any] = [
            SettingsKeys.chimeOnLocationUpdate.rawValue: true,
            SettingsKeys.accuracy.rawValue: kCLLocationAccuracyBest,
            SettingsKeys.showCrumbsBoundingArea.rawValue: true,
            SettingsKeys.activity.rawValue: CLActivityType.fitness.rawValue
        ]
        UserDefaults.standard.register(defaults: defaultPreferences)
        
        return true
    }
}

