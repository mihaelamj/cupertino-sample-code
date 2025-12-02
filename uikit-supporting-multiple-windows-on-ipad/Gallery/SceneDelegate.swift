/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that demonstrates how to use the scene delegate to configure a scene's interface and implements basic state restoration.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // Used as the activation condition for this scene.
    let mainSceneTargetContentIdentifier = "com.apple.gallery.mainIdentifier"

    var window: UIWindow?
    
    // MARK: - UIWindowSceneDelegate
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            if !configure(window: window, with: userActivity) {
                Swift.debugPrint("Failed to restore from \(userActivity)")
            }
        }
        // The 'window' property will automatically be loaded with the storyboard's initial view controller.
        
        // Set the activation predicates, which operate on the 'targetContentIdentifier'.
        let conditions = scene.activationConditions
        let prefsPredicate = NSPredicate(format: "self == %@", mainSceneTargetContentIdentifier)
        // The main predicate, which expresses to the system what kind of content the scene can display.
        conditions.canActivateForTargetContentIdentifierPredicate = prefsPredicate
        // The secondary predicate, which expresses to the system that this scene is especially interested in a particular kind of content.
        conditions.prefersToActivateForTargetContentIdentifierPredicate = prefsPredicate
    }
    
    // This delegate is called when the app is suspended to the background.
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }

    // This function is called when the app restores the selected photo.
    func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
        var configured = false

        guard activity.activityType == UserActivity.GalleryOpenDetailActivityType else { return configured }
        guard let navigationController = window?.rootViewController as? UINavigationController else { return configured }
            
        if let photoID = activity.userInfo?[UserActivity.GalleryOpenDetailPhotoAssetKey] as? String,
            let photoTitle = activity.userInfo?[UserActivity.GalleryOpenDetailPhotoTitleKey] as? String {
            // Restore the view controller with the 'photoID' and 'photoTitle'.
            if let photoDetailViewController = PhotoDetailViewController.loadFromStoryboard() {
                photoDetailViewController.photo = Photo(assetName: photoID, title: photoTitle)

                navigationController.pushViewController(photoDetailViewController, animated: false)
                configured = true
            }
        }
        return configured
    }
}
