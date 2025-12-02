/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A query interface for retrieving the app's featured trail collections.
*/

import AppIntents
import Foundation
import OSLog

/**
 `FeaturedCollectionEntityQuery` allows people to query the app for trail collections through a Find intent in the Shortcuts app,
 automatically providing filtering options based on the entity's properties — without the complexity of an `EntityPropertyQuery.`
 In this sample, the featured trail collections is a fixed list, and `TrailCollection` only has a small number of properties, making
 it a good choice for this query API. Large data sets, or entity types that require more memory, should use `EntityPropertyQuery`.
 
 `SuggestTrails` takes the output of the Find intent that this query creates, and uses it as an input.
 */
struct FeaturedCollectionEntityQuery: EnumerableEntityQuery {
    
    /// The text describing what this intent does, which the system displays to people in the Shortcuts app.
    static var findIntentDescription: IntentDescription? {
        IntentDescription("Find a featured trail collection.",
                          categoryName: "Discover",
                          searchKeywords: ["trail", "location", "travel"],
                          resultValueName: "Trails")
    }
    
    @Dependency
    private var trailManager: TrailDataManager
    
    /**
     All entity queries need to locate specific entities through their unique ID. When someone creates a shortcut and populates fields with
     specific values, the system stores and looks up the values through their unique identifiers.
     */
    func entities(for identifiers: [TrailCollection.ID]) async throws -> [TrailCollection] {
        Logger.entityQueryLogging.debug("[FeaturedCollectionEntityQuery] Query for IDs \(identifiers)")
        
        return trailManager.featuredTrailCollections
            .filter { identifiers.contains($0.id) }
    }
    
    /// - Returns: The most likely choices relevant to an individual.
    func suggestedEntities() async throws -> [TrailCollection] {
        Logger.entityQueryLogging.debug("[FeaturedCollectionEntityQuery] Request for suggested entities")
        
        // This example only returns a small number of suggestions to represent the most relevant choices to the individual.
        var result = trailManager.featuredTrailCollections
        result.removeFirst(7)
        return result
    }

    /**
     The complete collection of entities this query applies to.
     
     - Tag: enumerable_query
     */
    func allEntities() async throws -> [TrailCollection] {
        Logger.entityQueryLogging.debug("[FeaturedCollectionEntityQuery] Request for all entities")
        return trailManager.featuredTrailCollections
    }
}
