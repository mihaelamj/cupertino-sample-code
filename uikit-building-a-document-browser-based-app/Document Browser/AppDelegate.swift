/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An application delegate that support for opening shared documents.
*/

import UIKit

/** This app uses: "LSSupportsOpeningDocumentsInPlace" in the Info.plist:
    A Boolean value indicating whether the app may open the original document from a file provider, rather than a copy of the document.
    This will allow this app to open docs in place, appearing as: "Open in Document Browser" in the share sheet.
*/

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

}
