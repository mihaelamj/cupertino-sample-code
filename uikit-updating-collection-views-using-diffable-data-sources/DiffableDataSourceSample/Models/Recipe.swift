/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for a recipe.
*/

import UIKit

/// - Tag: Recipe
struct Recipe: Identifiable, Codable {
    var id: Int
    var title: String
    var prepTime: Int   // In seconds.
    var cookTime: Int   // In seconds.
    var servings: String
    var ingredients: String
    var directions: String
    var isFavorite: Bool
    var collections: [String]
    fileprivate var addedOn: Date? = Date()
    fileprivate var imageNames: [String]
}

extension Recipe {
    var addedOnDate: Date {
        addedOn ?? Date()
    }
    
    var subtitle: String {
        var subtitle = "\(self.servings) servings | "
        
        let (hours, minutes, seconds) = self.totalTime()
        if hours > 0 {
            subtitle += "\(hours) hr"
        }
        if minutes > 0 {
            if hours > 0 {
                subtitle += " "
            }
            subtitle += "\(minutes) min"
        }
        if seconds > 0 {
            if hours > 0 || minutes > 0 {
                subtitle += " "
            }
            subtitle = "\(seconds) sec"
        }
        
        return subtitle
    }

    var thumbnailImage: UIImage {
        guard let name = imageNames.last else { return #imageLiteral(resourceName: "placeholder") }
        return ImageStore.shared.image(name: name)
    }

    var smallImage: UIImage {
        guard imageNames.count >= 2 else { return thumbnailImage }
        
        let name = imageNames[1]
        return ImageStore.shared.image(name: name)
    }
    
    var fullImage: UIImage {
        guard let name = imageNames.first else { return #imageLiteral(resourceName: "placeholder") }
        return ImageStore.shared.image(name: name)
    }
    
    func add(_ image: UIImage) {
        guard let name = imageNames.first else { return }
        ImageStore.shared.add(image, with: name)
    }
}

extension Recipe {
    
    func totalTime() -> (Int, Int, Int) {
        return hoursMinutesSeconds(from: prepTime + cookTime)
    }

    fileprivate func hoursMinutesSeconds(from seconds: Int) -> (Int, Int, Int) {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        return (hours, minutes, remainingSeconds)
    }
    
}
