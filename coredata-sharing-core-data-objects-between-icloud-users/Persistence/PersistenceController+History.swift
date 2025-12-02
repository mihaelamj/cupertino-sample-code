/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that wrap the related methods for persistent history processing.
*/

import CoreData
import CloudKit

// MARK: - Notification handlers that trigger history processing.
//
extension PersistenceController {
    /**
     Handle .NSPersistentStoreRemoteChange notifications.
     Process persistent history to merge relevant changes to the context, and deduplicate the tags, if necessary.
     */
    @objc
    func storeRemoteChange(_ notification: Notification) {
        guard let storeUUID = notification.userInfo?[NSStoreUUIDKey] as? String,
              [privatePersistentStore.identifier, sharedPersistentStore.identifier].contains(storeUUID) else {
            print("\(#function): Ignore a store remote Change notification because of no valid storeUUID.")
            return
        }
        processHistoryAsynchronously(storeUUID: storeUUID)
    }
}

// MARK: - Process persistent history asynchronously.
//
extension PersistenceController {
    /**
     Process persistent history, posting any relevant transactions to the current view.
     This method processes the new history since the last history token, and is simply a fetch if there's no new history.
     */
    private func processHistoryAsynchronously(storeUUID: String) {
        historyQueue.addOperation {
            let taskContext = self.persistentContainer.newTaskContext()
            taskContext.performAndWait {
                self.performHistoryProcessing(storeUUID: storeUUID, performingContext: taskContext)
            }
        }
    }
    
    private func performHistoryProcessing(storeUUID: String, performingContext: NSManagedObjectContext) {
        /**
         Fetch the history by the other author since the last timestamp.
        */
        let lastHistoryToken = historyToken(with: storeUUID)
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
        let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
        historyFetchRequest.predicate = NSPredicate(format: "author != %@", TransactionAuthor.app)
        request.fetchRequest = historyFetchRequest

        if privatePersistentStore.identifier == storeUUID {
            request.affectedStores = [privatePersistentStore]
        } else if sharedPersistentStore.identifier == storeUUID {
            request.affectedStores = [sharedPersistentStore]
        }

        let result = (try? performingContext.execute(request)) as? NSPersistentHistoryResult
        guard let transactions = result?.result as? [NSPersistentHistoryTransaction] else {
            return
        }
        // print("\(#function): Processing transactions: \(transactions.count).")

        /**
         Post transactions so observers can update the UI, even when transactions is empty
         because when a share changes, Core Data triggers a store remote change notification with no transaction.
         */
        let userInfo: [String: Any] = [UserInfoKey.storeUUID: storeUUID, UserInfoKey.transactions: transactions]
        NotificationCenter.default.post(name: .cdcksStoreDidChange, object: self, userInfo: userInfo)
        /**
         Update the history token using the last transaction. The last transaction has the latest token.
         */
        if let newToken = transactions.last?.token {
            updateHistoryToken(with: storeUUID, newToken: newToken)
        }
        
        /**
         Limit to the private store so only owners deduplicate the tags. Owners have full access to the private database, and so
         don't need to worry about the permissions.
         */
        guard !transactions.isEmpty, storeUUID == privatePersistentStore.identifier else {
            return
        }
        /**
         Deduplicate the new tags.
         This only deduplicates the tags that aren't shared or have the same share.
         */
        var newTagObjectIDs = [NSManagedObjectID]()
        let tagEntityName = Tag.entity().name

        for transaction in transactions where transaction.changes != nil {
            for change in transaction.changes! {
                if change.changedObjectID.entity.name == tagEntityName && change.changeType == .insert {
                    newTagObjectIDs.append(change.changedObjectID)
                }
            }
        }
        if !newTagObjectIDs.isEmpty {
            deduplicateAndWait(tagObjectIDs: newTagObjectIDs)
        }
    }
    
    /**
     Track the last history tokens for the stores.
     The historyQueue reads the token when executing operations, and updates it after completing the processing.
     Access this user default from the history queue.
     */
    private func historyToken(with storeUUID: String) -> NSPersistentHistoryToken? {
        let key = "HistoryToken" + storeUUID
        if let data = UserDefaults.standard.data(forKey: key) {
            return  try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }
        return nil
    }
    
    private func updateHistoryToken(with storeUUID: String, newToken: NSPersistentHistoryToken) {
        let key = "HistoryToken" + storeUUID
        let data = try? NSKeyedArchiver.archivedData(withRootObject: newToken, requiringSecureCoding: true)
        UserDefaults.standard.set(data, forKey: key)
    }
}
