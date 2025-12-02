/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages user settings for the app.
*/

import AVFoundation

struct UserSettings {
    static let shared = UserSettings()
    
    private let userDefaults = UserDefaults.standard
    private let compositorTypeKey = "compositorType"
    
    private init() {}

    var compositorType: CompositorType {
        get {
            guard let rawValue = userDefaults.string(forKey: compositorTypeKey),
                  let type = CompositorType(rawValue: rawValue) else {
                #if os(visionOS)
                        return CompositorType.stereoOut
                #else
                        return CompositorType.monoOut
                #endif
            }
            return type
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: compositorTypeKey)
        }
    }
    
    func registerDefaults() {
        userDefaults.register(defaults: [compositorTypeKey: CompositorType.monoOut.rawValue])
    }
}
