/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model object describing the product displayed in both main and results tables.
*/

import Foundation

class Product: NSObject, Codable {
    
    enum CodingKeys: String, CodingKey {
        case title
        case yearIntroduced
        case introPrice
        case type
    }
    
    /// NSPredicate expression keys for searching.
    enum ExpressionKeys: String {
        case title
        case yearIntroduced
        case introPrice
        case type
    }
    
    enum ProductType: Int {
        case all = 0
        case birthdays = 1
        case weddings = 2
        case funerals = 3
    }
    
    class func productTypeName(forType: ProductType) -> String {
        switch forType {
        case .all:
            return NSLocalizedString("AllTitle", comment: "")
        case .birthdays:
            return NSLocalizedString("BirthdaysTitle", comment: "")
        case .weddings:
            return NSLocalizedString("WeddingsTitle", comment: "")
        case .funerals:
            return NSLocalizedString("FuneralsTitle", comment: "")
        }
    }
    
    // MARK: - Properties
    
    /** These properties need @objc to make them key value compliant when filtering using NSPredicate,
        and so they are accessible and usable in Objective-C to interact with other frameworks.
    */
    @objc var title: String
    @objc var yearIntroduced: Int
    @objc var introPrice: Double
    @objc var type: Int
    
    // MARK: - Initializers
    
    init(title: String, yearIntroduced: Int, introPrice: Double, type: ProductType) {
        self.title = title
        self.yearIntroduced = yearIntroduced
        self.introPrice = introPrice
        self.type = type.rawValue
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        yearIntroduced = try container.decode(Int.self, forKey: .yearIntroduced)
        introPrice = try container.decode(Double.self, forKey: .introPrice)
        type = try container.decode(Int.self, forKey: .type)
    }
    
    func formattedIntroPrice() -> String? {
        /** Build the price and year string.
            Use NSNumberFormatter to get the currency format out of this NSNumber (product.introPrice).
        */
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.formatterBehavior = .default
        return numberFormatter.string(from: NSNumber(value: introPrice))
    }
    
    // MARK: - Encoding
	
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(yearIntroduced, forKey: .yearIntroduced)
        try container.encode(introPrice, forKey: .introPrice)
        try container.encode(type, forKey: .type)
    }
    
}
