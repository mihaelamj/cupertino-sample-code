/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that wraps the related methods for managing ratings.
*/

import Foundation
import CoreData

// MARK: - Convenience methods for managing ratings.
//
extension PersistenceController {
   
     func addRating(value: Int16, relateTo photo: Photo) {
        if let context = photo.managedObjectContext {
            context.performAndWait {
                let rating = Rating(context: context)
                rating.value = value
                rating.photo = photo
                context.save(with: .addRating)
            }
        }
    }
    
    func deleteRating(_ rating: Rating) {
        if let context = rating.managedObjectContext {
            context.performAndWait {
                context.delete(rating)
                context.save(with: .deleteRating)
            }
        }
    }
}
