/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The backing data store that provides recipe data to the app.
*/

import UIKit
import ImageIO

// A reference to the app's backing data store. This data store
// retrieves recipe data from the file system. In a real-world
// app, a data store might contain data from other sources such as
// Core Data or web services.
let dataStore = DataStore(recipes: load("recipeData.json"))

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

final class ImageStore {
    typealias _ImageDictionary = [String: UIImage]
    fileprivate var images: _ImageDictionary = [:]

    fileprivate static var scale = 2
    
    static var shared = ImageStore()
    
    func image(name: String) -> UIImage {
        let index = _guaranteeImage(name: name)
        return images.values[index]
    }
    
    func add(_ image: UIImage, with name: String) {
        images[name] = image
    }

    static func loadImage(name: String) -> UIImage {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
            let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            fatalError("Couldn't load image \(name).jpg from the main bundle.")
        }
        return UIImage(cgImage: cgImage, scale: CGFloat(ImageStore.scale), orientation: .up)
    }
    
    fileprivate func _guaranteeImage(name: String) -> _ImageDictionary.Index {
        if let index = images.index(forKey: name) { return index }
        
        images[name] = ImageStore.loadImage(name: name)
        return images.index(forKey: name)!
    }
}

class DataStore {
    var allRecipes: [Recipe]
    var collections: [String]
    
    init(recipes: [Recipe]) {
        self.allRecipes = recipes
        self.collections = DataStore.collection(from: recipes)
    }

    func favoriteRecipes() -> [Recipe] {
        return allRecipes.filter { $0.isFavorite }
    }
    
    func recentRecipes(age: Int = 30) -> [Recipe] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -age, to: Date()) ?? Date()
        return dataStore.allRecipes.filter { $0.addedOnDate > thirtyDaysAgo }
    }

    func recipesInCollection(_ collectionName: String?) -> [Recipe] {
        if let name = collectionName {
            return allRecipes.filter { $0.collections.contains(name) }
        } else {
            return []
        }
        
    }
    
    fileprivate static func collection(from recipes: [Recipe]) -> [String] {
        var allCollections = Set<String>()
        for recipe in recipes {
            allCollections.formUnion(recipe.collections)
        }
        return allCollections.sorted()
    }
    
    func newRecipe() -> Recipe {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let json = """
            {
                "id": 0,
                "title": "New Recipe",
                "prepTime": 0,
                "cookTime": 0,
                "servings": "",
                "ingredients": "",
                "directions": "",
                "isFavorite": false,
                "collections": [],
                "imageNames": []
            }
        """
        let data = Data(json.utf8)
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Recipe.self, from: data)
        } catch {
            fatalError("Invalid recipe JSON.")
        }
    }
    
    func add(_ recipe: Recipe) -> Recipe {
        var recipeToAdd = recipe
        recipeToAdd.id = (allRecipes.map { $0.id }.max() ?? 0) + 1
        allRecipes.append(recipeToAdd)
        updateCollectionsIfNeeded()

        NotificationCenter.default.post(
            name: .recipeDidAdd,
            object: self,
            userInfo: [NotificationKeys.recipeId: recipe.id, NotificationKeys.recipe: recipe])

        return recipeToAdd
    }
    
    @discardableResult
    func delete(_ recipe: Recipe) -> Bool {
        var deleted = false
        if let index = allRecipes.firstIndex(where: { $0.id == recipe.id }) {
            allRecipes.remove(at: index)
            deleted = true
            updateCollectionsIfNeeded()

            NotificationCenter.default.post(
                name: .recipeDidDelete,
                object: self,
                userInfo: [NotificationKeys.recipeId: recipe.id, NotificationKeys.recipe: recipe])
        }
        return deleted
    }
    
    @discardableResult
    func update(_ recipe: Recipe) -> Recipe? {
        var recipeToReturn: Recipe? = nil // Return nil if the recipe doesn't exist.
        if let index = allRecipes.firstIndex(where: { $0.id == recipe.id }) {
            allRecipes[index] = recipe
            recipeToReturn = recipe
            updateCollectionsIfNeeded()

            NotificationCenter.default.post(
                name: .recipeDidChange,
                object: self,
                userInfo: [NotificationKeys.recipeId: recipe.id, NotificationKeys.recipe: recipe])
        }
        return recipeToReturn
    }
    
    func recipe(with id: Int) -> Recipe? {
        return allRecipes.first(where: { $0.id == id })
    }

    fileprivate func updateCollectionsIfNeeded() {
        let updatedCollection = DataStore.collection(from: allRecipes)
        if collections != updatedCollection {
            collections = updatedCollection
            NotificationCenter.default.post(
                name: .recipeCollectionsDidChange,
                object: self,
                userInfo: [NotificationKeys.recipeCollections: collections])
        }
    }
    
}
