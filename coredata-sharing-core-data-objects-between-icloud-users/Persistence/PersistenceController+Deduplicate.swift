/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that wraps the related methods for deduplicating tags.
*/

import CoreData
import CloudKit

// MARK: - Deduplicate tags.
//
extension PersistenceController {
    /**
     Deduplicate tags that have the same name and are in the same CloudKit record zone, one tag at a time, on the historyQueue.
     All peers eventually reach the same result with no coordination or communication.
  
     When detecting a duplicate tag,  this sample doesn’t delete it immediately because that can lead to a relationship loss.
     Consider the following flow as an example:
     1. A user simultaneously adds tag A on device A, and tag B on device B. Tag A is related to photo A on device A.
     2. Core Data synchronizes tag A to device B first. On device B, tagA->photoA is nil at the moment because photo A isn't there yet.
     3. On device B, the app looks into the persistent history, detects tag A, and triggers the deduplication process.
     4. Assuming tag B is the one to reserve, the app deletes tag A. The app can’t relate tag B to photo A because tagA->photoA is nil.
     5. Core Data synchronizes the deletion of tag A back to device A, together with tag B.
     6. On device A, Core Data adds tag B, deletes tag A, and triggers a remote change notification.
     7. On device A, the app looks into the persistent history, detects tag B, and triggers the deduplication process.
     8. The app can't relate tag B to photo A because of the deletion in step 6, and so loses the tagA->photoA relationship.

     When more peers get involved, the app can trigger multiple deduplications before Core Data synchronizes the related photos, so
     gating the deletion in step 4 by checking tagA.photos is empty doesn't help.
     
     To avoid losing relationships, this sample implements the following strategy:
     a. When detecting a duplicate tag, it marks it as deduplicated rather than deleting it immediately. Therefore, in step 6 of the above flow,
     Core Data updates tag A rather than deleting it, and the tagA->photoA relationship is still there.
     
     b. In the deduplication process, it picks a tag to reserve, which isn't a deduplicated one, and passes the relationships of all other tags to it,
     including the deduplicated ones. Therefore, in step 8 of the above flow, the app finds tag A and the tagA->photoA relationship,
     and changes the relationship to tagB->photoA.
     
     c. In the handler of NSPersistentCloudKitContainer.eventChangedNotification, it deletes the tags that the app deduplicates sometime
     before the last export and import events. The "sometime" needs to be long enough for Core Data to synchronize all the relevant relationships,
     which can be weeks or months based on how long or how often the user runs the app, and also the number of deduplicated tags in the store.
     
     d. It deletes the deduplicated tags when the user deletes the reserved tag so the deduplicated tags don't come into play anymore.
     */

    func deduplicateAndWait(tagObjectIDs: [NSManagedObjectID])
    {
        /**
         Make any store changes on a background context with the transaction author name of this app.
         Use performAndWait to serialize the steps. historyQueue runs in the background so this doesn't block the main queue.
         */
        let taskContext = persistentContainer.newTaskContext()
        taskContext.performAndWait {
            tagObjectIDs.forEach { tagObjectID in
                deduplicate(tagObjectID: tagObjectID, performingContext: taskContext)
            }
            taskContext.save(with: .deduplicateAndWait)
        }
    }

    /**
     Deduplicate one single tag.
     */
    private func deduplicate(tagObjectID: NSManagedObjectID, performingContext: NSManagedObjectContext) {
        /**
         tag.name can be nil when the app inserts a tag and immediately deletes it before processing the insertion .
         In that case, silently ignore the deleted tag.
         */
        guard let tag = performingContext.object(with: tagObjectID) as? Tag,
              let tagName = tag.name else {
            print("\(#function): Ignore a tag that was deleted: \(tagObjectID)")
            return
        }
        /**
         Fetch all tags with the same name, and sort them by uuid. Return if there are no duplicates.
         The fetch includes the deduplicated tags because they can have relationships that the app might replace with the reserved tag.
         */
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Tag.Schema.uuid.rawValue, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "\(Tag.Schema.name.rawValue) == %@", tagName)
        guard var duplicatedTags = try? performingContext.fetch(fetchRequest), duplicatedTags.count > 1 else {
            return
        }
        
        /**
         Filter out the tags that aren't in the same CloudKit record zone.
         Only tags that have the same name and are in the same record zone are duplicates.
         The tag zone ID can be nil, which means it isn't a shared tag. The filter rule is still valid in that case.
         */
        let tagZoneID = persistentContainer.recordID(for: tag.objectID)?.zoneID
        duplicatedTags = duplicatedTags.filter {
            self.persistentContainer.recordID(for: $0.objectID)?.zoneID == tagZoneID
        }
        /**
         Pick the tag to reserve, which can’t be a deduplicated one.
         */
        guard duplicatedTags.count > 1,
              let indexToReserve = duplicatedTags.firstIndex(where: { $0.deduplicatedDate == nil }) else {
            return
        }
        print("\(#function): Deduplicating tag with name: \(tagName), count: \(duplicatedTags.count)")
        
        let tagToReserve = duplicatedTags[indexToReserve]
        duplicatedTags.remove(at: indexToReserve)
        markAsDeduplicated(duplicatedTags: duplicatedTags, tagToReserve: tagToReserve, performingContext: performingContext)
    }
    
    /**
     Relate the photos to the reserved tag, disconnect the relationships to the tag so the tag doesn't get involved in the next relevant
     deduplication, and mark the duplicate tags as deduplicated by setting the deduplicated date to .now.
     */
    private func markAsDeduplicated(duplicatedTags: [Tag], tagToReserve: Tag, performingContext: NSManagedObjectContext) {
        duplicatedTags.forEach { tag in
            if let photoSet = tag.photos {
                for case let photo as Photo in photoSet {
                    photo.removeFromTags(tag)
                    photo.addToTags(tagToReserve)
                }
            }
            /**
             Mark the tag as deduplicated if the tag isn't deduplicated by setting deduplicatedDate to .now.
             Don't change the deduplicated date of a tag that's already deduplicated because that triggers an infinite synchronization loop.
             */
            if tag.deduplicatedDate == nil {
                tag.deduplicatedDate = .now
            }
        }
    }
}

extension PersistenceController {
    /**
     Handle the container's event change notifications (NSPersistentCloudKitContainer.eventChangedNotification).
     */
    @objc
    func containerEventChanged(_ notification: Notification)
    {
         guard let value = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey],
              let event = value as? NSPersistentCloudKitContainer.Event else {
            print("\(#function): Failed to retrieve the container event from notification.userInfo.")
            return
        }
        guard event.succeeded else {
            if let error = event.error {
                print("\(#function): Received a persistent CloudKit container event with error\n\(error)")
            }
            return
        }
        /**
         Record the timestamp of the last successful import and export.
         */
        let lastExportDateKey = "LastExportDate", lastImportDateKey = "LastImportDate"
        if let endDate = event.endDate {
            if event.type == .export {
                UserDefaults.standard.set(endDate, forKey: lastExportDateKey)
            } else if event.type == .import {
                UserDefaults.standard.set(endDate, forKey: lastImportDateKey)
            } else {
                return
            }
        }
        /**
         Only remove deduplicated tags up to once per 60 seconds.
         60: For testing purposes. Real-world apps need to choose the value based on their concrete data set.
         */
        let lastRemoveDeduplicatedTagsDateKey = "LastRemoveDeduplicatedTagsDate"
        if let theDate = UserDefaults.standard.value(forKey: lastRemoveDeduplicatedTagsDateKey) as? Date,
           Date.now.timeIntervalSince(theDate) < 60 {
            return
        }
        /**
         Remove tags that the app deduplicated 60 seconds before the last successful synchronization,
         and record the last remove deduplicated tags date.
         -60: For testing purposes. Real-world apps need to choose the value based on their concrete data set.
         */
        if let lastExportDate = UserDefaults.standard.value(forKey: lastExportDateKey) as? Date,
           let lastImportDate = UserDefaults.standard.value(forKey: lastImportDateKey) as? Date {
            let earlierDate = min(lastExportDate, lastImportDate)
            removeDeduplicatedTags(beforeDate: Date(timeInterval: -60, since: earlierDate))
            UserDefaults.standard.set(Date.now, forKey: lastRemoveDeduplicatedTagsDateKey)
        }
    }
    
    /**
     Remove the deduplicated tags. NSBatchDeleteRequest doesn't respect NSFetchRequest.affectedStores, so use context.delete(_:).
     */
    private func removeDeduplicatedTags(beforeDate: Date) {
        let taskContext = persistentContainer.newTaskContext()
        taskContext.perform {
            let fetchRequest = Tag.fetchRequest()
            fetchRequest.affectedStores = [self.privatePersistentStore]
            let format = "(\(Tag.Schema.deduplicatedDate.rawValue) != nil) AND (\(Tag.Schema.deduplicatedDate.rawValue) < %@)"
            fetchRequest.predicate = NSPredicate(format: format, beforeDate as CVarArg)
            
            if let tags = try? taskContext.fetch(fetchRequest), !tags.isEmpty {
                print("\(#function): Removing deduplicated tags with name: \(tags.first?.name ?? "nil"), count: \(tags.count).")
                for tag in tags {
                    taskContext.delete(tag)
                }
                taskContext.save(with: .removeDeduplicatedTags)
            }
        }
    }
}
