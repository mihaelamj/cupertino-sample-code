/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App Entity for `ToppingAppEntity`.
*/

import Foundation
import AppIntents
import SoupKit

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct ToppingAppEntity: AppEntity {
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Topping")

    struct ToppingAppEntityQuery: EntityQuery {
        func entities(for identifiers: [ToppingAppEntity.ID]) async throws -> [ToppingAppEntity] {
            let result = Order.MenuItemTopping.allCases.map { (topping) -> ToppingAppEntity in
                return ToppingAppEntity(
                    id: topping.rawValue, displayString: topping.localizedName(useDeferredIntentLocalization: true))
            }
            return result
        }
        
        /// - Tag: entitiesString
        func entities(matching string: String) async throws -> [ToppingAppEntity] {
            let menuItemTopping = Order.MenuItemTopping.allCases.filter { $0.rawValue == string }
            let result = menuItemTopping.map { (topping) -> ToppingAppEntity in
                return ToppingAppEntity(
                    id: topping.rawValue, displayString: topping.localizedName(useDeferredIntentLocalization: true))
            }
            return result
        }

        func suggestedEntities() async throws -> [ToppingAppEntity] {
            let result = Order.MenuItemTopping.allCases.map { (topping) -> ToppingAppEntity in
                return ToppingAppEntity(
                    id: topping.rawValue, displayString: topping.localizedName(useDeferredIntentLocalization: true))
            }
            return result
        }
    }
    
    static var defaultQuery = ToppingAppEntityQuery()

    var id: String // If the identifier isn't a String, conform the entity to `EntityIdentifierConvertible`.
    var displayString: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)")
    }

    init(id: String, displayString: String) {
        self.id = id
        self.displayString = displayString
    }
}

