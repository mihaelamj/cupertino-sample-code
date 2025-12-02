/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that wrap the methods related to the iOS sharing management UI.
*/

import UIKit
import CloudKit

/**
 Create and present a UICloudSharingController object for CloudKit sharing management.
 This sample uses ShareLink to create a new share, and  uses UICloudSharingController to manage an existing share in iOS.
 */
extension PersistenceController {
    func presentCloudSharingController(share: CKShare) {
        let sharingController = UICloudSharingController(share: share, container: cloudKitContainer)
        sharingController.delegate = self
        /**
         Setting the presentation style to .formSheet so there's no need to specify sourceView, sourceItem, or sourceRect.
         */
        if let viewController = rootViewController {
            sharingController.modalPresentationStyle = .formSheet
            viewController.present(sharingController, animated: true)
        }
    }
    
    private var rootViewController: UIViewController? {
        for scene in UIApplication.shared.connectedScenes {
            if scene.activationState == .foregroundActive,
               let sceneDeleate = (scene as? UIWindowScene)?.delegate as? UIWindowSceneDelegate,
               let window = sceneDeleate.window {
                return window?.rootViewController
            }
        }
        print("\(#function): Failed to retrieve the window's root view controller.")
        return nil
    }
}

/**
 Implement UICloudSharingControllerDelegate.
 Since iOS 16.4, iPadOS 16.4, macOS 13.3, and watchOS 9.4, NSPersistentCloudKitContainer observes the changes from the system sharing UI,
 and updates the share it maintains. Therefore, the sample app doesn't need to do anything for the synchronization between UICloudSharingController
 and Core Data.
 
 To support earlier systems that can't upgrade to the latest versions, consider implementing cloudSharingControllerDidSaveShare(:)  and
 cloudSharingControllerDidStopSharing(:) here to call persistUpdatedShare(:in:completion:)  and purgeObjectsAndRecordsInZone(with:in:completion:),
 respectively.
 */
extension PersistenceController: UICloudSharingControllerDelegate {
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return "A cool photo!"
    }
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
    }
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
    }
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("\(#function): Failed to save a share: \(error)")
    }
}
