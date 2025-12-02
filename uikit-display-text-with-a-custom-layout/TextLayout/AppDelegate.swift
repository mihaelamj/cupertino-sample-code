/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate class that Xcode generates.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Create a shared text storage from Sample.rtf.
    //
    lazy var textStorage: NSTextStorage = {
        guard let fileURL = Bundle.main.url(forResource: "Sample", withExtension: "rtf") else {
            fatalError("Failed to find Sample.rtf in the app bundle.")
        }
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf]
        guard let textStorage = try? NSTextStorage(url: fileURL, options: options, documentAttributes: nil) else {
            fatalError("Failed to create a text storage from \(fileURL).")
        }
        return textStorage
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
