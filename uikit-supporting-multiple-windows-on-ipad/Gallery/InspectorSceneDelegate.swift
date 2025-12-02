/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that demonstrates how to use the scene delegate to configure the inspector interface, and also implements basic state restoration.
*/

import UIKit

class InspectorSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    // Used in the 'NSUserActivity' as part of the Inspector scene, and as the activation condition for this scene.
    static let inspectorSceneTargetContentIdentifier = "com.apple.gallery.inspectorIdentifier"

    // 'UserInfo' key to mark this session with a particular photo asset.
    static let sessionUserInfoAssetKey = "photoAsset"

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Define a new window scene and attach the Inspector window and its view controller.
        
        // Find any user activity (from a new connection or state restoration) that's available and configure it accordingly.
        if let newUserActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            // A user activity was found; configure the session with it.
            if configure(window: window, session: session, with: newUserActivity) {
                scene.userActivity = newUserActivity // Remember this activity for when this app is suspended or quit.
            } else {
                Swift.debugPrint("Failed to restore scene from \(newUserActivity)")
            }
            
            // Set the 'can' and 'prefers' predicates for this scene.
            let conditions = scene.activationConditions
            
            // The 'can' or main predicate expresses to the system what kind of content the scene can display.
            let canPredicate = NSPredicate(format: "self == %@", InspectorSceneDelegate.inspectorSceneTargetContentIdentifier)
            conditions.canActivateForTargetContentIdentifierPredicate = canPredicate
            
            // The 'prefer' or secondary predicate, expresses to the system that this scene
            // is "especially" interested in a particular kind of content.
            if let photoAsset = newUserActivity.userInfo![UserActivity.GalleryOpenDetailPhotoAssetKey] as? String {
                let preferPredicate =
                    NSPredicate(format: "self == %@",
                                "\(InspectorSceneDelegate.inspectorSceneTargetContentIdentifier)-\(photoAsset)")
                conditions.prefersToActivateForTargetContentIdentifierPredicate = preferPredicate
            }
        } else {
            // No user activity to restore here.
        }

        if let viewController = window!.rootViewController {
            window?.windowScene?.sizeRestrictions?.minimumSize =
                CGSize(width: viewController.preferredContentSize.width, height: viewController.preferredContentSize.height)
            
            /* For macOS, optionally you can choose to block window resizing by making the min and max the same values.
            window?.windowScene?.sizeRestrictions?.maximumSize =
                CGSize(width: viewController.preferredContentSize.width, height: viewController.preferredContentSize.height)
            */
        }
    }
    
    func configure(window: UIWindow?, session: UISceneSession, with activity: NSUserActivity) -> Bool {
        // Configure and restore this Inspector window from the input 'activity'.
        activity.delegate = self // So the delegate 'userActivityWillSave' can be called by iOS.

        guard let navController = window!.rootViewController as? UINavigationController else { return false }

        if let viewController = navController.topViewController {
            viewController.userActivity = activity
            
            // Mark the session with a specific photo, so you can check for it later if you want to reactivate this scene.
            session.userInfo =
                [InspectorSceneDelegate.sessionUserInfoAssetKey: activity.userInfo![UserActivity.GalleryOpenDetailPhotoAssetKey] as Any]
        }
        
        // Set the scene title; this will be seen in the app switcher as the title of the scene, or for Mac Catalyst the window title.
        if activity.userInfo != nil {
            window?.windowScene?.title = activity.userInfo?[UserActivity.GalleryOpenDetailPhotoTitleKey] as? String
        }
        
        return true
    }
    
    // This delegate is called when the app is suspended to the background.
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }
    
    // Look for an already open scene session that matches the photo asset.
    class func activeInspectorSceneSessionForPhoto(_ photoAsset: String) -> UISceneSession? {
        var foundSceneSession: UISceneSession!

        for session in UIApplication.shared.openSessions
            where session.configuration.delegateClass == InspectorSceneDelegate.self {
            if let userInfo = session.userInfo {
                if userInfo[sessionUserInfoAssetKey] as? String == photoAsset {
                    // An open session was found that matches the photo to activate.
                    foundSceneSession = session
                    break
                }
            }
        }
        return foundSceneSession
    }
    
    class func openInspectorSceneSessionForPhoto(_ photo: Photo, requestingScene: UIWindowScene, errorHandler: ((Error) -> Void)? = nil) {
        let options = UIWindowScene.ActivationRequestOptions()
        options.preferredPresentationStyle = .prominent
        options.requestingScene = requestingScene // The scene object that requested the activation of a different scene.
        
        // Present this scene as a secondary window separate from the main window.
        //
        // Look for an already open window scene session that matches the photo.
        if let foundSceneSession = InspectorSceneDelegate.activeInspectorSceneSessionForPhoto(photo.assetName) {
            // Inspector scene session already open, so activate it.
            UIApplication.shared.requestSceneSessionActivation(foundSceneSession, // Activate the found scene session.
                                                               userActivity: nil, // No need to pass activity for an already open session.
                                                               options: options,
                                                               errorHandler: errorHandler)
        } else {
            // No Inspector scene session found, so create a new one.
            let userActivity = photo.inspectorUserActivity
    
            UIApplication.shared.requestSceneSessionActivation(nil, // Pass nil means make a new one.
                                                               userActivity: userActivity,
                                                               options: options,
                                                               errorHandler: errorHandler)
        }
    }

    /** Use this method to provide immediate feedback to the user that an activity is about to continue.
        iOS calls this method as soon as the user confirms that an activity should be continued but possibly
        before the data associated with that activity is available.
    */
    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
        //..
    }
    
    /** iOS calls this method when it receives the data associated with the user activity.
        Use the data stored in the NSUserActivity object to re-create the user’s activity.
        This method is your opportunity to update your app so that it can perform the associated task.
     */
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == UserActivity.GalleryOpenInspectorActivityType else { return }
        
        // Pass the user activity product over to this view controller.
        if let navController = window?.rootViewController as? UINavigationController {
            if let secondViewController = navController.topViewController as? InspectorViewController {
                secondViewController.userActivity = userActivity
            }
        }
    }

    /** Use this method to let the user know that the specified activity couldn't be continued.
        If you don't implement this method, AppKit displays an error to the user with an appropriate message about the reason for the failure.
     */
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        let continueAlert = UIAlertController(title: "Unable to continue activity",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            continueAlert.dismiss(animated: true, completion: nil)
        }
        continueAlert.addAction(okAction)
        window?.rootViewController?.present(continueAlert, animated: true, completion: nil)
    }
}

// MARK: - NSUserActivityDelegate

extension InspectorSceneDelegate: NSUserActivityDelegate {
    // Notified that the user activity will be saved to be continued or persisted.
    func userActivityWillSave(_ userActivity: NSUserActivity) {
       //..
    }
    
}
