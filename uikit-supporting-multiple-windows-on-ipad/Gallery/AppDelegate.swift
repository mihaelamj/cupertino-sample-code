/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A basic app delegate implementation that demonstrates how to return a particular UISceneConfiguration for a new scene session.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // It's important that each UISceneConfiguration have a unique configuration name.
        var configurationName: String!

        switch options.userActivities.first?.activityType {
        case UserActivity.GalleryOpenInspectorActivityType:
            configurationName = "Inspector Configuration" // Create a photo inspector window scene.
        default:
            configurationName = "Default Configuration" // Create a default gallery window scene.
        }
        
        return UISceneConfiguration(name: configurationName, sessionRole: connectingSceneSession.role)
    }
    
#if targetEnvironment(macCatalyst)
    // Insert the "Inspect" key command to inspect individual photos.
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        // This menu key command is handled, managed, and validated by 'GalleryViewController'.
        let inspectCommand =
            UIKeyCommand(title: "Inspect",
                         image: nil,
                         action: #selector(GalleryViewController.inspect),
                         input: "I",
                         modifierFlags: .command,
                         propertyList: nil)
        let inspectMenu =
            UIMenu(title: "Inspect",
                   image: nil,
                   identifier: UIMenu.Identifier("inspect"),
                   options: .displayInline,
                   children: [inspectCommand])
        builder.insertSibling(inspectMenu, afterMenu: .newScene)
    }
#endif
    
}
