/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structure for representing an iTunes item.
*/

import Foundation

struct Product {
    /// The title of the product.
    var title: String
    /// The iTunes identifier of the product.
    var productIdentifier: String
    /// Indicates whether the product is an app.
    var isApplication: Bool
    /// The App Analytics campaign token.
    var campaignToken: String
    /// The App Analytics provider token.
    var providerToken: String
}

// MARK: - Product Extension

extension Product: Decodable {
    private enum CodingKeys: CodingKey {
        case title, productIdentifier, isApplication, campaignToken, providerToken
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        
        /*
            Throw an error if the value of the title or productIdentifier is an
            empty string. Provide these data as the README file explains.
        */
        if title.isEmpty {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.title,
                                                       in: values,
                                         debugDescription: "The title property cannot be set to an empty string. Update its value in Products.plist.")
        }
        
        productIdentifier = try values.decode(String.self, forKey: .productIdentifier)
        if productIdentifier.isEmpty {
          let description = "The productIdentifier property cannot be set to an empty string. Update its value in Products.plist."
          throw DecodingError.dataCorruptedError(forKey: CodingKeys.productIdentifier,
                                                     in: values,
                                       debugDescription: description)
        }
        
        isApplication = try values.decode(Bool.self, forKey: .isApplication)
        campaignToken = try values.decode(String.self, forKey: .campaignToken)
        providerToken = try values.decode(String.self, forKey: .providerToken)
    }
}
