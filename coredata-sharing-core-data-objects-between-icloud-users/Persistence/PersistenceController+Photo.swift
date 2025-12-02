/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that wraps the related methods for managing photos.
*/

import Foundation
import ImageIO
import CoreData
import CloudKit
import CoreTransferable
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Convenient methods for managing photos.
//
extension PersistenceController {
    func addPhoto(imageData: Data) {
        guard let thumbnailData = thumbnail(with: imageData)?.jpegData(compressionQuality: 1) else {
            print("\(#function): Failed to create a thumbnail for the picked image.")
            return
        }
        let taskContext = persistentContainer.newTaskContext()
        addPhoto(photoData: imageData, thumbnailData: thumbnailData, context: taskContext)
    }
    
    func delete(photo: Photo) {
        if let context = photo.managedObjectContext {
            context.perform {
                context.delete(photo)
                context.save(with: .deletePhoto)
            }
        }
    }
    
    func photoTransactions(from notification: Notification) -> [NSPersistentHistoryTransaction] {
        var results = [NSPersistentHistoryTransaction]()
        if let transactions = notification.userInfo?[UserInfoKey.transactions] as? [NSPersistentHistoryTransaction] {
            let photoEntityName = Photo.entity().name
            for transaction in transactions where transaction.changes != nil {
                for change in transaction.changes! where change.changedObjectID.entity.name == photoEntityName {
                    results.append(transaction)
                    break // Jump to the next transaction.
                }
            }
        }
        return results
    }
    
    func mergeTransactions(_ transactions: [NSPersistentHistoryTransaction], to context: NSManagedObjectContext) {
        context.perform {
            for transaction in transactions {
                context.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
            }
        }
    }
    
    private func addPhoto(photoData: Data, thumbnailData: Data, tagNames: [String] = [], context: NSManagedObjectContext) {
        context.perform {
            /**
             A new photo always goes to the private persistent store.
             */
            let photo = Photo(context: context)
            context.assign(photo, to: self.privatePersistentStore)
            photo.uniqueName = UUID().uuidString
            
            let thumbnail = Thumbnail(context: context)
            thumbnail.data = thumbnailData
            thumbnail.photo = photo
            
            let photoDataObject = PhotoData(context: context)
            photoDataObject.data = photoData
            photoDataObject.photo = photo
            
            for tagName in tagNames {
                let existingTag = Tag.tagIfExists(with: tagName, context: context)
                let tag = existingTag ?? Tag(context: context)
                tag.name = tagName
                tag.addToPhotos(photo)
            }

            context.save(with: .addPhoto)
        }
    }

    private func thumbnail(with imageData: Data, pixelSize: Int = 120) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelSize
        ]
        let imageReference = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)!
        return UIImage(cgImage: imageReference)
    }
}

extension Photo {
    var tagsNotDeduplicated: [Tag]? {
        if let allTags = tags?.allObjects as? [Tag] {
            return allTags.filter {
               $0.deduplicatedDate == nil
            }
        }
        return nil
    }
}

#if os(iOS) || os(macOS)
extension Photo: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CKShareTransferRepresentation { photoToExport in
            let persistentContainer = PersistenceController.shared.persistentContainer
            let ckContainer = PersistenceController.shared.cloudKitContainer

            var photoShare: CKShare?
            if let shareSet = try? persistentContainer.fetchShares(matching: [photoToExport.objectID]),
               let (_, share) = shareSet.first {
                photoShare = share
            }
            /**
             Return the existing share if the photo already has a share.
             */
            if let share = photoShare {
                return .existing(share, container: ckContainer)
            }
            /**
             Otherwise, create a new share for the photo and return it.
             Use uriRepresentation of the object in the Sendable closure.
             */
            let photoURI = photoToExport.objectID.uriRepresentation()
            return .prepareShare(container: ckContainer) {
                let persistentContainer = PersistenceController.shared.persistentContainer
                let photo = await persistentContainer.viewContext.perform {
                    let coordinator = persistentContainer.viewContext.persistentStoreCoordinator
                    guard let objectID = coordinator?.managedObjectID(forURIRepresentation: photoURI) else {
                        fatalError("Failed to return the managed objectID for: \(photoURI).")
                    }
                    return persistentContainer.viewContext.object(with: objectID)
                }
                let (_, share, _) = try await persistentContainer.share([photo], to: nil)
                return share
            }
        }
    }
}
#endif
