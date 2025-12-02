/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The watch app delegate class.
*/

import WatchKit
import CloudKit

class AppDelegate: NSObject, WKApplicationDelegate {
    /**
     To be able to accept a share, add a CKSharingSupported entry in the Info.plist file of the WatchKit app and set it to true.
     */
    func userDidAcceptCloudKitShare(with cloudKitShareMetadata: CKShare.Metadata) {
        let persistenceController = PersistenceController.shared
        let sharedStore = persistenceController.sharedPersistentStore
        let container = persistenceController.persistentContainer
        container.acceptShareInvitations(from: [cloudKitShareMetadata], into: sharedStore) { (_, error) in
            if let error = error {
                print("\(#function): Failed to accept share invitations: \(error)")
            }
        }
    }
}
