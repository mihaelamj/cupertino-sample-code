/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This class demonstrates how to use the scene delegate to configure a scene's interface.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UISplitViewControllerDelegate {
    var window: UIWindow?
    
    var detailViewManager: DetailViewManager!
    
    /** Applications configure their UIWindow, and attach the UIWindow to the provided UIWindowScene scene.
 
        Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
     
        If using a storyboard file (as specified by the Info.plist key, UISceneStoryboardFile,
        the window property will automatically be configured by UIKit and attached to the windowScene.
 
        Remember to retain the SceneDelegate 's UIWindow.
        The recommended approach is for the SceneDelegate to retain the scene's window.
    */
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let splitViewController = window!.rootViewController as? UISplitViewController {
            detailViewManager = DetailViewManager()
            detailViewManager.splitViewController = splitViewController
        }
    }

}
