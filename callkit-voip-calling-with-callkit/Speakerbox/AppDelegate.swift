/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    class var shared: AppDelegate! {
        return UIApplication.shared.delegate as? AppDelegate
    }

    let pushRegistry = PKPushRegistry(queue: .main)
    let callManager = SpeakerboxCallManager()
    var providerDelegate: ProviderDelegate?

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]

        providerDelegate = ProviderDelegate(callManager: callManager)

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let handle = url.startCallHandle else {
            print("Could not determine start call handle from URL: \(url)")
            return false
        }

        callManager.startCall(handle: handle)
        return true
    }

    private func application(_ application: UIApplication,
                             continue userActivity: NSUserActivity,
                             restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let handle = userActivity.startCallHandle else {
            print("Could not determine start call handle from user activity: \(userActivity)")
            return false
        }

        guard let isVideo = userActivity.isVideo else {
            print("Could not determine video from user activity: \(userActivity)")
            return false
        }

        callManager.startCall(handle: handle, video: isVideo)
        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

}

// MARK: - PKPushRegistryDelegate
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        /*
         Store push credentials on the server for the active user.
         For sample app purposes, do nothing, because everything is done locally.
         */
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType, completion: @escaping () -> Void) {
        defer {
            completion()
        }

        guard type == .voIP,
            let uuidString = payload.dictionaryPayload["UUID"] as? String,
            let handle = payload.dictionaryPayload["handle"] as? String,
            let hasVideo = payload.dictionaryPayload["hasVideo"] as? Bool,
            let uuid = UUID(uuidString: uuidString)
            else {
                return
        }

        displayIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo)
    }

    // MARK: - PKPushRegistryDelegate Helper

    /// Display the incoming call to the user.
    func displayIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((Error?) -> Void)? = nil) {
        providerDelegate?.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: completion)
    }

}
