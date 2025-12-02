/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App Entity for `SoupAppEntity`.
*/

import Foundation
import AppIntents
import SoupKit

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct SoupAppEntity: AppEntity {
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Soup")
    /// - Tag: entityQuery
    struct SoupAppEntityQuery: EntityStringQuery {
        func entities(matching string: String) async throws -> IntentItemCollection<SoupAppEntity> {
            let soupMenuManager = SoupMenuManager()
            
            let allItems = soupMenuManager.findItems(
                exactlyMatching: [.available, .regularItem], [.available, .dailySpecialItem], [.available, .secretItem], searchTerm: string)
            
            return ItemCollection {
                ItemSection<SoupAppEntity>(
                    title: "Regulars",
                    items:
                        allItems .map {
                            IntentItem<SoupAppEntity>(
                                SoupAppEntity($0),
                                title: SoupAppEntity($0).localizedStringResource,
                                image: SoupAppEntity($0).displayRepresentation.image)
                        }
                )
            }
        }
        
        func entities(for identifiers: [SoupAppEntity.ID]) async throws -> [SoupAppEntity] {
            let soupMenuManager = SoupMenuManager()
            return identifiers.compactMap {
                guard let menuItem = soupMenuManager.findItem(by: $0) else { return nil }
                return SoupAppEntity(menuItem)
            }
        }

        func entities(matching string: String) async throws -> [SoupAppEntity] {
            let soupMenuManager = SoupMenuManager()
            let allItems = soupMenuManager.findItems(
                exactlyMatching: [.available, .regularItem], [.available, .dailySpecialItem], [.available, .secretItem], searchTerm: string)
            return  allItems.map { SoupAppEntity($0) }
        }
        /// - Tag: suggestedEntities
        func suggestedEntities() async throws -> IntentItemCollection<SoupAppEntity> {
            let soupMenuManager = SoupMenuManager()
            
            // Only adopt `EntityStringQuery` for searching large catalogs, not for small static collections.
            // The Shortcuts app supports filtering of small collections by default.
            let availableRegularItems = soupMenuManager.findItems(exactlyMatching: [.available, .regularItem])
            let availableDailySpecialItems = soupMenuManager.findItems(exactlyMatching: [.available, .dailySpecialItem])
            
            return ItemCollection {
                ItemSection<SoupAppEntity>(
                    items:
                        availableRegularItems .map {
                            IntentItem<SoupAppEntity>(
                                SoupAppEntity($0),
                                title: SoupAppEntity($0).localizedStringResource,
                                image: SoupAppEntity($0).displayRepresentation.image)
                        }
                )
                ItemSection<SoupAppEntity>(
                    title: "Specials",
                    items: availableDailySpecialItems .map {
                        IntentItem<SoupAppEntity>(
                            SoupAppEntity($0),
                            title: SoupAppEntity($0).localizedStringResource,
                            image: SoupAppEntity($0).displayRepresentation.image)
                    }
                )
            }
        }
    }
    
    static var defaultQuery = SoupAppEntityQuery()
    
    var id: String // If the identifier isn't a String, conform the entity to `EntityIdentifierConvertible`.
    var displayString: String
    var imageName: String
    var description: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)", subtitle: "\(description)", image: .init(named: imageName))
    }
  
    init(id: String, displayString: String, description: String, imageName: String) {
      self.id = id
      self.displayString = displayString
      self.description = description
      self.imageName = imageName
    }
                                                                  
    init(_ menuItem: MenuItem) {
        self.init(id: menuItem.id.rawValue,
            displayString: menuItem.localizedName(useDeferredIntentLocalization: false),
            description: menuItem.localizedItemDescription(useDeferredIntentLocalization: false),
            imageName: menuItem.iconImageName)
    }
    
}

