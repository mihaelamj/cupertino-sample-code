/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that wrap the related methods for managing tags.
*/

import Foundation
import CoreData
import CloudKit

// MARK: - Convenient methods for managing tags.
//
extension PersistenceController {
    func numberOfTags(with tagName: String) -> Int {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.predicate = Tag.predicateExcludingDeduplicatedTags(name: tagName)
        let number = try? persistentContainer.viewContext.count(for: fetchRequest)
        return number ?? 0
    }

    func addTag(name: String, relateTo photo: Photo) {
        if let context = photo.managedObjectContext {
            context.performAndWait {
                let tag = Tag(context: context)
                tag.name = name
                tag.uuid = UUID()
                tag.deduplicatedDate = nil
                tag.addToPhotos(photo)
                context.save(with: .addTag)
            }
        }
    }
    
    func deleteTag(_ tag: Tag) {
        /**
         Remove the deduplicated tags using a background context.
         */
        if let tagZoneID = persistentContainer.recordID(for: tag.objectID)?.zoneID,
           let tagName = tag.name {
            let taskContext = persistentContainer.newTaskContext()
            taskContext.perform {
                self.removeDeduplicatedTags(tagName: tagName, tagZoneID: tagZoneID, performingContext: taskContext)
                taskContext.save(with: .removeDeduplicatedTags)
            }
        }
        if let context = tag.managedObjectContext {
            context.performAndWait {
                context.delete(tag)
                context.save(with: .deleteTag)
            }
        }
    }
    
    func toggleTagging(photo: Photo, tag: Tag) {
        if let context = photo.managedObjectContext {
            context.performAndWait {
                if let photoTags = photo.tagsNotDeduplicated, photoTags.contains(tag) {
                    photo.removeFromTags(tag)
                } else {
                    photo.addToTags(tag)
                }
                context.save(with: .toggleTagging)
            }
        }
    }
    /**
     Return the tags that the app can use to tag the specified photo (or the tags that are in the same CloudKit zone).
     */
    func filterTags(from tags: [Tag], forTagging photo: Photo) -> [Tag] {
        guard !tags.isEmpty else {
            return []
        }
        guard let context = photo.managedObjectContext else {
            print("\(#function): Tagging a photo that isn't in a context is unsupported.")
            return []
        }
        /**
         Fetch the share for the photo.
         */
        var photoShare: CKShare?
        if let result = try? persistentContainer.fetchShares(matching: [photo.objectID]) {
            photoShare = result[photo.objectID]
        }
        /**
         Gather the object IDs of the tags that are valid for tagging the photo.
         - Tags that are already in the tags of the photo are valid.
         - Tags that have the same share as photoShare are valid.
         */
        var filteredTags = [Tag]()
        context.performAndWait {
            let photoTagNotDeduplicated = photo.tagsNotDeduplicated
            for tag in tags {
                if let photoTags = photoTagNotDeduplicated, photoTags.contains(tag) {
                    filteredTags.append(tag)
                    continue
                }
                let tagShare = existingShare(tag: tag)
                if photoShare?.recordID.zoneID == tagShare?.recordID.zoneID {
                    filteredTags.append(tag)
                }
            }
        }
        return filteredTags
    }
    
    /**
     Fetch and return the share of the tag and its related photos.
     Consider the related photos as well.
     */
    private func existingShare(tag: Tag) -> CKShare? {
        var objectIDs = [tag.objectID]
        if let photoSet = tag.photos, let photos = Array(photoSet) as? [Photo] {
            objectIDs += photos.map { $0.objectID }
        }
        let result = try? persistentContainer.fetchShares(matching: objectIDs)
        return result?.values.first
    }
    
    /**
     Remove the deduplicated tags with the tag name and CloudKit record zone ID.
     */
    private func removeDeduplicatedTags(tagName: String, tagZoneID: CKRecordZone.ID, performingContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        let format = "(\(Tag.Schema.deduplicatedDate.rawValue) != nil) AND (\(Tag.Schema.name.rawValue) == %@)"
        fetchRequest.predicate = NSPredicate(format: format, tagName)
        guard var duplicatedTags = try? performingContext.fetch(fetchRequest) else {
            return
        }
        duplicatedTags = duplicatedTags.filter {
            self.persistentContainer.recordID(for: $0.objectID)?.zoneID == tagZoneID
        }
        duplicatedTags.forEach { tag in
            performingContext.delete(tag)
        }
    }
}

// MARK: - An extension for Tag.
//
extension Tag {
    /**
     The name of relevant tag attributes.
     */
    enum Schema: String {
        case name, uuid, deduplicatedDate
    }
    
    class func predicateExcludingDeduplicatedTags(name: String, useContains: Bool = false) -> NSPredicate {
        let baseFormat = "\(Tag.Schema.deduplicatedDate.rawValue) == nil"
        if name.isEmpty {
            return NSPredicate(format: baseFormat)
        }
        var nameFormat = "\(Tag.Schema.name.rawValue) == %@"
        if useContains {
            nameFormat = "\(Tag.Schema.name.rawValue) CONTAINS[cd] %@"
        }
        let fullFormat = "(\(nameFormat)) AND (\(baseFormat))"
        return NSPredicate(format: fullFormat, argumentArray: [name])
    }

    class func tagIfExists(with name: String, context: NSManagedObjectContext) -> Tag? {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.predicate = predicateExcludingDeduplicatedTags(name: name)
        let tags = try? context.fetch(fetchRequest)
        return tags?.first
    }
}
