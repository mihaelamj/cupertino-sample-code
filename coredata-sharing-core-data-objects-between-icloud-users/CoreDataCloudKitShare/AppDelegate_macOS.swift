/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The macOS app delegate class.
*/

import CoreData
import CloudKit
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        let persistenceController = PersistenceController.shared
        let sharedStore = persistenceController.sharedPersistentStore
        let container = persistenceController.persistentContainer
        container.acceptShareInvitations(from: [metadata], into: sharedStore) { (_, error) in
            if let error = error {
                print("\(#function): Failed to accept share invitations: \(error)")
            }
        }
    }
}
