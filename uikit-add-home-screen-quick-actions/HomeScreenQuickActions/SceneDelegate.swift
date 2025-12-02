/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The UIWindowSceneDelegate for this sample app.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // List of known shortcut actions.
    enum ActionType: String {
        case searchAction = "SearchAction"
        case shareAction = "ShareAction"
        case favoriteAction = "FavoriteAction"
    }
    
    static let favoriteIdentifierInfoKey = "FavoriteIdentifier"
    
    var window: UIWindow?
    var savedShortCutItem: UIApplicationShortcutItem!
    
    /// - Tag: willConnectTo
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        /** Process the quick action if the user selected one to launch the app.
            Grab a reference to the shortcutItem to use in the scene.
        */
        if let shortcutItem = connectionOptions.shortcutItem {
            // Save it off for later when we become active.
            savedShortCutItem = shortcutItem
        }
    }

    // MARK: - Application Shortcut Support
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "Quick Action", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        /** In this sample an alert is being shown to indicate that the action has been triggered,
            but in real code the functionality for the quick action would be triggered.
        */
        if let actionTypeValue = ActionType(rawValue: shortcutItem.type) {
            switch actionTypeValue {
            case .searchAction:
                showAlert(message: "Search triggered")
            case .shareAction:
                showAlert(message: "Share triggered")
            case .favoriteAction:
                // Go to that particular favorite shortcut.
                if let favoriteIdentifier = shortcutItem.userInfo?[SceneDelegate.favoriteIdentifierInfoKey] as? String {
                    // Find the favorite contact from the userInfo identifier.
                    if let foundFavoriteContact = ContactsData.shared.contact(favoriteIdentifier) {
                        // Go to that favorite contact.
                        if let navController = window?.rootViewController as? UINavigationController {
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            if let contactsDetailViewController =
                                storyboard.instantiateViewController(identifier: "ContactDetailViewController") as? ContactDetailViewController {
                                // Pass the contact to the detail view controller and push it.
                                contactsDetailViewController.contact = foundFavoriteContact
                                navController.pushViewController(contactsDetailViewController, animated: false)
                            }
                        }
                    }
                }
            }
        }
        return true
    }
        
    /** Called when the user activates your application by selecting a shortcut on the Home Screen,
        and the window scene is already connected.
    */
    /// - Tag: PerformAction
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        let handled = handleShortCutItem(shortcutItem: shortcutItem)
        completionHandler(handled)
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if savedShortCutItem != nil {
            _ = handleShortCutItem(shortcutItem: savedShortCutItem)
        }
    }
    
    /// - Tag: SceneWillResignActive
    func sceneWillResignActive(_ scene: UIScene) {
        // Transform each favorite contact into a UIApplicationShortcutItem.
        let application = UIApplication.shared
        application.shortcutItems = ContactsData.shared.favoriteContacts.map { contact -> UIApplicationShortcutItem in
            return UIApplicationShortcutItem(type: ActionType.favoriteAction.rawValue,
                                             localizedTitle: contact.name,
                                             localizedSubtitle: contact.email,
                                             icon: UIApplicationShortcutIcon(systemImageName: "star.fill"),
                                             userInfo: contact.quickActionUserInfo)
        }
    }
}

