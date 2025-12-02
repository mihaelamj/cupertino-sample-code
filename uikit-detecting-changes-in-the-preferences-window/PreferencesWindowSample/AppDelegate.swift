/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// - Tag: didFinishLaunching
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // To ensure that the app has a good set of preference values, register
        // the default values each time the app launches.
        registerDefaultPreferenceValues()

        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: - Preferences
    
    /// - Tag: registerDefaultPreferenceValues
    func registerDefaultPreferenceValues() {
        let preferenceSpecifiers = retrieveSettingsBundlePreferenceSpecifiers(from: "Root.plist")
        let defaultValuesToRegister = parse(preferenceSpecifiers)

        // Register the default values with the registration domain.
        UserDefaults.standard.register(defaults: defaultValuesToRegister)
    }
    
    /// - Tag: parsePreferenceSpecifiers
    func parse(_ preferenceSpecifiers: [NSDictionary]) -> [String: Any] {
        var defaultValuesToRegister = [String: Any]()

        // Parse the preference specifiers, copying the default values
        // into the `defaultValuesToRegister` dictionary.
        for preferenceItem in preferenceSpecifiers {
            if let key = preferenceItem["Key"] as? String,
                let defaultValue = preferenceItem["DefaultValue"] {
                defaultValuesToRegister[key] = defaultValue
            }

            // Add child pane preference specifiers.
            if let type = preferenceItem["Type"] as? String,
                type == "PSChildPaneSpecifier" {
                if var file = preferenceItem["File"] as? String {
                    if file.hasSuffix(".plist") == false {
                        file += ".plist"
                    }
                    let morePreferenceSpecifiers = retrieveSettingsBundlePreferenceSpecifiers(from: file)
                    let moreDefaultValuesToRegister = parse(morePreferenceSpecifiers)
                    defaultValuesToRegister.merge(moreDefaultValuesToRegister) { (current, _) in current }
                }
            }
        }
        
        return defaultValuesToRegister
    }
    
    func retrieveSettingsBundlePreferenceSpecifiers(from plistFileName: String) -> [NSDictionary] {
        // Get the URL of the Settings.bundle.
        guard
            let settingsBundleURL = Bundle.main.url(forResource: "Settings", withExtension: "bundle")
            else {
                os_log("Settings.bundle not found.")
                return [NSDictionary]()
        }

        // Load the contents of the component into a dictionary.
        let rootURL = settingsBundleURL.appendingPathComponent(plistFileName)
        guard
            let settingsPlist = NSDictionary(contentsOf: rootURL)
            else {
                os_log("Settings.bundle doesn't contain %s.", plistFileName)
                return [NSDictionary]()
        }

        // Load the preference specifiers into a dictionary.
        guard
            let preferenceSpecifiers = settingsPlist["PreferenceSpecifiers"] as? [NSDictionary]
            else {
                os_log("%s is missing the PreferenceSpecifiers array.", plistFileName)
                return [NSDictionary]()
        }

        return preferenceSpecifiers
    }

}
