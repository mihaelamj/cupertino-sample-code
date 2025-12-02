/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension of the app's types to integrate the app's data into Spotlight.
*/

import AppIntents
import Foundation
import OSLog

// CoreSpotlight isn't available in watchOS.
#if canImport(CoreSpotlight)
import CoreSpotlight

extension Trail {
    /**
     Define the information about a trail to include in the Spotlight search index.
     - Tag: searchable_attributes
     */
    var searchableAttributes: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        
        attributes.title = name
        attributes.namedLocation = regionDescription
        attributes.keywords = activities.localizedElements
        
        attributes.latitude = NSNumber(value: coordinate.latitude)
        attributes.longitude = NSNumber(value: coordinate.longitude)
        attributes.supportsNavigation = true
        
        return attributes
    }
}

/**
 Allow Spotlight to index `TrailEntity` by conforming to the `IndexedEntity` protocol.
 
 This sample project uses the `Trail` structure to contain all of the data on a trail, and integrates that data into the Spotlight search index.
 Because this sample app shows an example of a data type where the app represents only a subset of the complete data as an entity, the app
 doesn't need to implement the `attributeSet` property of `IndexedEntity` to contribute the searchable information for the entity
 to Spotlight. Instead, it associates the `TrailEntity` with the underlying`Trail` data in `updateSpotlightIndex()`.
 */
extension TrailEntity: IndexedEntity {
    
}

extension TrailDataManager {

    // - Tag: spotlight_association
    func updateSpotlightIndex() async {
        guard CSSearchableIndex.isIndexingAvailable() else {
            Logger.spotlightLogging.info("[Spotlight] Indexing is unavailable")
            return
        }
        
        // Create an array of the searchable information for each `Trail`.
        let searchableItems = trails.map { trail in
            let item = CSSearchableItem(uniqueIdentifier: String(trail.id),
                                        domainIdentifier: nil,
                                        attributeSet: trail.searchableAttributes)
            
            let isFavorite = favoritesCollection.members.contains(trail.id)
            let weight = isFavorite ? 10 : 1
            let intent = TrailEntity(trail: trail)
            
            /**
             Associate `TrailEntity` with the data that the `Trail` structure provides so the system recognizes that
             both types represent the same data. You need to create this association before adding the `CSSearchableItem`
             to a `CSSearchableIndex`.
             */
            item.associateAppEntity(intent, priority: weight)
            return item
        }
        
        do {
            // Add the trails to the search index so people can find them through Spotlight.
            // You need to do this as part of the app's initial setup on launch.
            let index = CSSearchableIndex.default()
            try await index.indexSearchableItems(searchableItems)
            Logger.spotlightLogging.info("[Spotlight] Trails indexed by Spotlight")
        } catch let error {
            Logger.spotlightLogging.error("[Spotlight] Trails were not indexed by Spotlight. Reason: \(error.localizedDescription)")
        }
    }
}

#endif // canImport(CoreSpotlight)
