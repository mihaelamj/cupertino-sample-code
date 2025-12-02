/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that wrap the common functions related to sharing.
*/

import Foundation
import CoreData
import CloudKit

extension PersistenceController {
    func shareObject(_ unsharedObject: NSManagedObject, to existingShare: CKShare?,
                     completionHandler: ((_ share: CKShare?, _ error: Error?) -> Void)? = nil)
    {
        persistentContainer.share([unsharedObject], to: existingShare) { (objectIDs, share, container, error) in
            guard error == nil, let share = share else {
                print("\(#function): Failed to share an object: \(error!))")
                completionHandler?(share, error)
                return
            }
            /**
             Deduplicate tags because adding a photo to an existing share moves the entire object graph to the shared record zone,
             which can lead to duplicated tags.
             */
            if existingShare != nil {
                if let tagObjectIDs = objectIDs?.filter({ $0.entity.name == "Tag" }), !tagObjectIDs.isEmpty {
                    self.deduplicateAndWait(tagObjectIDs: Array(tagObjectIDs))
                }
            } else {
                self.configure(share: share)
            }
            /**
             Synchronize the changes on the share to the private persistent store.
             */
            self.persistentContainer.persistUpdatedShare(share, in: self.privatePersistentStore) { (share, error) in
                if let error = error {
                    print("\(#function): Failed to persist updated share: \(error)")
                }
                completionHandler?(share, error)
            }
        }
    }
    
    /**
     Delete the Core Data objects and the records in the CloudKit record zone associated with the share.
     The purge API deletes the zone from CloudKit, and also the object graph from the Core Data store.
     Apps that need to keep the object graph can make a deep copy, ensure the new graph doesn't connect to any share,
     and save it to the store
     */
    func purgeObjectsAndRecords(with shareRecordID: CKRecord.ID, in persistentStore: NSPersistentStore? = nil) {
        guard let store = (persistentStore ?? persistentStoreForShare(with: shareRecordID)) else {
            print("\(#function): Failed to find the persistent store for share. \(shareRecordID))")
            return
        }
        persistentContainer.purgeObjectsAndRecordsInZone(with: shareRecordID.zoneID, in: store) { (zoneID, error) in
            if let error = error {
                print("\(#function): Failed to purge objects and records: \(error)")
            }
        }
    }

    func existingShare(photo: Photo) -> CKShare? {
        if let shareSet = try? persistentContainer.fetchShares(matching: [photo.objectID]),
           let (_, share) = shareSet.first {
            return share
        }
        return nil
    }
    
    func share(with title: String) -> CKShare? {
        let stores = [privatePersistentStore, sharedPersistentStore]
        let shares = try? persistentContainer.fetchShares(in: stores)
        let share = shares?.first(where: { $0.title == title })
        return share
    }
    
    func shareTitles() -> [String] {
        let stores = [privatePersistentStore, sharedPersistentStore]
        let shares = try? persistentContainer.fetchShares(in: stores)
        return shares?.map { $0.title } ?? []
    }
    
    func isParticipatingShare(with title: String) -> Bool {
        let shares = try? persistentContainer.fetchShares(in: [sharedPersistentStore])
        let share = shares?.first(where: { $0.title == title })
        return share == nil ? false : true
    }
    
    func configure(share: CKShare, with photo: Photo? = nil) {
        share[CKShare.SystemFieldKey.title] = "A cool photo"
    }
}

extension PersistenceController {
    func addParticipant(emailAddress: String, permission: CKShare.ParticipantPermission = .readWrite, share: CKShare,
                        completionHandler: ((_ share: CKShare?, _ error: Error?) -> Void)?) {
        /**
         Use the email address to look up the participant from the private store. Return if the participant doesn't exist.
         Use privatePersistentStore directly because only the owner may add participants to a share.
         */
        let lookupInfo = CKUserIdentity.LookupInfo(emailAddress: emailAddress)
        let persistentStore = privatePersistentStore //share.persistentStore!

        persistentContainer.fetchParticipants(matching: [lookupInfo], into: persistentStore) { (results, error) in
            guard let participants = results, let participant = participants.first, error == nil else {
                completionHandler?(share, error)
                return
            }
                  
            participant.permission = permission
            participant.role = .privateUser
            share.addParticipant(participant)
            
            self.persistentContainer.persistUpdatedShare(share, in: persistentStore) { (share, error) in
                if let error = error {
                    print("\(#function): Failed to persist updated share: \(error)")
                }
                completionHandler?(share, error)
            }
        }
    }
    
    func deleteParticipant(_ participants: [CKShare.Participant], share: CKShare,
                           completionHandler: ((_ share: CKShare?, _ error: Error?) -> Void)?) {
        for participant in participants {
            share.removeParticipant(participant)
        }
        /**
         Use privatePersistentStore directly because only the owner may delete the participants of a share.
         */
        persistentContainer.persistUpdatedShare(share, in: privatePersistentStore) { (share, error) in
            if let error = error {
                print("\(#function): Failed to persist updated share: \(error)")
            }
            completionHandler?(share, error)
        }
    }
}

extension PersistenceController {
    /**
     Return the persistent store that contains the share with a zone ID that matches shareRecordID, or nil if there isn't such a store.
     */
    func persistentStoreForShare(with shareRecordID: CKRecord.ID) -> NSPersistentStore? {
        if let shares = try? persistentContainer.fetchShares(in: privatePersistentStore) {
            let zoneIDs = shares.map { $0.recordID.zoneID }
            if zoneIDs.contains(shareRecordID.zoneID) {
                return privatePersistentStore
            }
        }
        if let shares = try? persistentContainer.fetchShares(in: sharedPersistentStore) {
            let zoneIDs = shares.map { $0.recordID.zoneID }
            if zoneIDs.contains(shareRecordID.zoneID) {
                return sharedPersistentStore
            }
        }
        return nil
    }
    
    func persistentStoreForShare(_ share: CKShare) -> NSPersistentStore? {
        return persistentStoreForShare(with: share.recordID)
    }
}
