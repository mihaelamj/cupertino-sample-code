/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main data model for this app containing a list of products.
*/

import Foundation

/** Note that we use an observable object class for the model,
    so that its values are globally shared, and integrate with scene storage.
*/
class ProductsModel: Codable, ObservableObject {
    @Published var products: [Product] = []
    
    private enum CodingKeys: String, CodingKey {
        case products
    }
    
    // The archived file name, name saved to Documents folder.
    private let dataFileName = "Products"
    
    init() {
        // Load the data model from the 'Products' data file found in the Documents directory.
        if let codedData = try? Data(contentsOf: dataModelURL()) {
            // Decode the json file into a DataModel object.
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([Product].self, from: codedData) {
                products = decoded
            }
        } else {
            // No data on disk, read the products from json file.
            products = Bundle.main.decode("products.json")
            save()
        }
    }
    
    // MARK: - Codable
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(products, forKey: .products)
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        products = try values.decode(Array.self, forKey: .products)
    }
    
    private func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    private func dataModelURL() -> URL {
        let docURL = documentsDirectory()
        return docURL.appendingPathComponent(dataFileName)
    }

    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(products) {
            do {
                // Save the 'Products' data file to the Documents directory.
                try encoded.write(to: dataModelURL())
            } catch {
                print("Couldn't write to save file: " + error.localizedDescription)
            }
        }
    }
}

// MARK: Bundle

extension Bundle {
    func decode(_ file: String) -> [Product] {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }
        let decoder = JSONDecoder()
        guard let loaded = try? decoder.decode([Product].self, from: data) else {
            fatalError("Failed to decode \(file) from bundle.")
        }
        return loaded
    }
}
