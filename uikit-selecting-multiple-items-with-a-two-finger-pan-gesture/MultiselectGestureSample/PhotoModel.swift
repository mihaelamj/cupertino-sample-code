/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A photo model to display in the collection view.
*/

import UIKit

struct PhotoModel {
    
    let name: String
    var image: UIImage? {
        return UIImage(systemName: name)
    }
    
    static func generatePhotosItems(count: Int) -> [PhotoModel] {
        var items = [PhotoModel]()
        for _ in 1...count {
            items.append(generatePhotoItem())
        }
        return items
    }
    
    static private var lastName: String = ""
    
    static private var names: [String] = {
        var array = [String]()
        for index in 1...25 {
            array.append("\(index).square")
        }
        return array
    }()
    
    static private func generatePhotoItem() -> PhotoModel {
        // Get a name that is different from the last name.
        var name: String
        repeat {
            name = randomName(from: names)
        } while name == lastName
        lastName = name
        
        return PhotoModel(name: name)
    }
    
    static private func randomName(from array: [String]) -> String {
        return array[randomNumber(upperLimit: array.count)]
    }
    
    static private func randomNumber(upperLimit: Int) -> Int {
        return Int(arc4random() % UInt32(upperLimit))
    }
    
}
