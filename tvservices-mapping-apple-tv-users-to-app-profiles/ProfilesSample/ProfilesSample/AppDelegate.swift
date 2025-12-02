/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate contains the basic logic to determine when to show the
 profile picker and the sign-in screen.
*/

import UIKit
import TVServices
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var tabBarController: UITabBarController?

    private let profileData = ProfileData()
    private let keychainController = KeychainController()
    private let userManager = TVUserManager()

    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let homeViewController = HomeViewController(profileData: profileData)
        let settingsViewController = SettingsViewController()
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [homeViewController, settingsViewController]
        self.tabBarController = tabBarController

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        presentSignInIfNeeded()

        return true
    }

    /// Present the app's profile picker panel.
    func presentProfilePicker() {
        guard let rootViewController = window?.rootViewController else {
            return
        }

        let picker = ProfilePickerViewController(profileData: profileData)
        rootViewController.present(picker, animated: true)
    }

    /// Delete the existing preferred profile identifier for the current user.
    /// This is just a debugging helper.
    func resetPreferences() {
        profileData.deselectProfile()
    }

    /// Remove credentials from the keychain, and display the sign-in UI.
    func signOut() {
        keychainController.removeCredentials()
        presentSignIn()
        tabBarController?.selectedIndex = 0
    }

    private func presentSignInIfNeeded() {
        if keychainController.credentials == nil {
            presentSignIn()
        } else {
            presentProfilePickerIfNeeded()
        }
    }

    private func presentSignIn() {
        guard let rootViewController = window?.rootViewController else {
            return
        }

        let signInView = SignInView(
            keychainController: keychainController,
            didSignInHandler: { [weak self] in
                rootViewController.dismiss(animated: false)
                self?.presentProfilePickerIfNeeded()
            })
        let signInViewController = UIHostingController(rootView: signInView)
        rootViewController.present(signInViewController, animated: true)
    }

    private func presentProfilePickerIfNeeded() {
        if #available(tvOS 16.0, *) {
            // On tvOS 16, present the profile picker only if the Apple TV
            // doesn't have multiple users, or the current user hasn't picked a
            // profile yet.
            if !userManager.shouldStorePreferencesForCurrentUser || profileData.selectedProfile == nil {
                presentProfilePicker()
            }
        } else {
            // Always present the profile picker on tvOS 15 and earlier.
            presentProfilePicker()
        }
    }
}
