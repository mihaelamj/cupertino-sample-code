/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to Bundle
 The `static func findURLFilterControlNetworkExtensionBundleID() -> String` is added as a convenience to traverse
 the main bundle to identify the bundle ID of the first encountered bundle representing a EXAppExtension configured
 as a `url-filter-control`.
 This bundle identifier is needed by the NEURLFilterManager as part of the configuration used to identify the app
 extension providing the `NEURLFilterControlProvider` implementation.
*/

import Foundation

extension Bundle {
    static func findURLFilterControlNetworkExtensionBundleID() -> String? {
        /* Look for a bundle whose Info.plist contains the `com.apple.networkextension.url-filter-control`
           value for the `EXExtensionPointIdentifier` key inside the `EXAppExtensionAttributes` dictionary.

           <key>EXAppExtensionAttributes</key>
               <dict>
               <key>EXExtensionPointIdentifier</key>
                   <string>com.apple.networkextension.url-filter-control</string>
               </dict>
         */

        let enumerator = FileManager.default.enumerator(at: Bundle.main.bundleURL, includingPropertiesForKeys: [.nameKey])
        while let url = enumerator?.nextObject() as? URL {
            let name = (try? url.resourceValues(forKeys: [.nameKey]))?.name ?? ""
            if name.hasSuffix(".appex") {
                guard let bundle = Bundle(url: url),
                      let appExtAttrDict = bundle.infoDictionary?["EXAppExtensionAttributes"] as? [String: Any],
                      let extensionPointIdentifier = appExtAttrDict["EXExtensionPointIdentifier"] as? String,
                      extensionPointIdentifier == "com.apple.networkextension.url-filter-control" else {
                    continue
                }
                return bundle.bundleIdentifier
            }
        }
        return nil
    }
}
