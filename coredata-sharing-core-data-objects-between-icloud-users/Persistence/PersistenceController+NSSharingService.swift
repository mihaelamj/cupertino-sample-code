/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that wrap the methods related to the macOS sharing management UI.
*/

import AppKit
import CloudKit

/**
 Create and present an NSSharingService object for CloudKit sharing management.
 This sample uses ShareLink to create a new share, and uses NSSharingService to manage an existing share in macOS.
 */
extension PersistenceController {
    func presentCloudSharingController(share: CKShare) {
        guard let sharingService = NSSharingService(named: .cloudSharing) else {
            print("\(#function): Failed to create an NSSharingService instance for cloud sharing.")
            return
        }
        sharingService.delegate = self
        
        let itemProvider = NSItemProvider()
        itemProvider.registerCloudKitShare(share, container: cloudKitContainer)
        
        if sharingService.canPerform(withItems: [itemProvider]) {
            sharingService.perform(withItems: [itemProvider])
        } else {
            print("\(#function): Sharing service can't perform with \([itemProvider]).")
        }
    }
}

/**
 Implement NSCloudSharingServiceDelegate.
 Since iOS 16.4, iPadOS 16.4, macOS 13.3, and watchOS 9.4, NSPersistentCloudKitContainer observes the changes from the system sharing UI,
 and updates the share it maintains. Therefore, the sample app doesn't need to do anything for the synchronization between NSCloudSharingService
 and Core Data.
 
 To support earlier systems that can't upgrade to the latest versions, consider implementing sharingService(:didSave:)  and
 sharingService(:didStopSharing:) to call persistUpdatedShare(:in:completion:)  and purgeObjectsAndRecordsInZone(with:in:completion:), respectively.
 
 There’s no need to implement options(for:share:) because this sample only uses NSSharingService for managing an existing share.
 */
extension PersistenceController: NSCloudSharingServiceDelegate {
    func sharingService(_ sharingService: NSSharingService, willShareItems items: [Any]) {
    }
    func sharingService(_ sharingService: NSSharingService, didSave share: CKShare) {
    }
    func sharingService(_ sharingService: NSSharingService, didStopSharing share: CKShare) {
    }
    /**
     The cloud-sharing service invokes this method when the user finishes sharing or dismisses the service’s view controller.
     It calls this method, if it exists, instead of  sharingService(:didFailToShareItems:error:) and sharingService(:didShareItems:).
     */
    func sharingService(_ sharingService: NSSharingService, didCompleteForItems items: [Any], error: Error?) {
        if let error = error {
            print("\(#function): Cloud sharing service can't share the items \(items) \n \(error)")
        }
    }
}
