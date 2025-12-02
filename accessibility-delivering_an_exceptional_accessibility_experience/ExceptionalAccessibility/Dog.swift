/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contains the Dog struct and a helper for initializing test data.
*/

import UIKit

/**
 Dog model housing all of the data for each different dog up for adoption.
 */
struct Dog {
    // MARK: Properties

    var name: String
    var images: [UIImage]
    var breed: String
    var age: Float
    var weight: Float
    var shelterName: String

    var featuredImage: UIImage? {
        return images.first
    }

    // MARK: Initializers

    init(name: String, images: [UIImage], breed: String, age: Float, weight: Float, shelterName: String) {
        self.name = name
        self.images = images
        self.breed = breed
        self.age = age
        self.weight = weight
        self.shelterName = shelterName
    }

    /// Convenience initializer for faked data
    static var all: [Dog] {
        return [
            Dog(name: "Lilly", images: [#imageLiteral(resourceName: "husky"), #imageLiteral(resourceName: "husky"), #imageLiteral(resourceName: "husky")], breed: "Corgi", age: 5, weight: 26, shelterName: "Cupertino Animal Shelter"),
            Dog(name: "Mr. Hammond", images: [#imageLiteral(resourceName: "husky")], breed: "Pug", age: 2, weight: 23, shelterName: "Cupertino Animal Shelter"),
            Dog(name: "Bubbles", images: [#imageLiteral(resourceName: "husky"), #imageLiteral(resourceName: "husky"), #imageLiteral(resourceName: "husky")], breed: "Golden Retriever", age: 8, weight: 65, shelterName: "Cupertino Animal Shelter"),
            Dog(name: "Pinky", images: [#imageLiteral(resourceName: "husky")], breed: "Maltese", age: 4, weight: 28, shelterName: "Cupertino Animal Shelter")
        ]
    }

}

extension Dog: Equatable {
    static func ==(lhs: Dog, rhs: Dog) -> Bool {
        return lhs.name == rhs.name &&
               lhs.images == rhs.images &&
               lhs.breed == rhs.breed &&
               lhs.age == rhs.age &&
               lhs.weight == rhs.weight &&
               lhs.shelterName == rhs.shelterName
    }
}
