/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate for the HapticSampler app.
*/

import UIKit
import CoreHaptics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var supportsHaptics: Bool = false
    
    /// - Tag: CheckHapticCompatibility
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Check if the device supports haptics.
        let hapticCapability = CHHapticEngine.capabilitiesForHardware()
        supportsHaptics = hapticCapability.supportsHaptics
        
        return true
    }
}

