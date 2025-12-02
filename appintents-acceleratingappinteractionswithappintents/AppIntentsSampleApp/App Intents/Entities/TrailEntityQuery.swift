/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A type that allows the system to query the app for its trail data.
*/

import AppIntents
import Foundation
import OSLog

/**
 An `EntityQuery` provides the basis for working with the app's custom types through the `AppEntity` protocol, allowing
 the system to query the app for entities by identifier and allowing the app to return a list of the most common entities.
 */
struct TrailEntityQuery: EntityQuery {
    
    @Dependency
    var trailManager: TrailDataManager
    
    /**
     All entity queries need to locate specific entities through their unique ID. When someone creates a shortcut and populates fields with
     specific values, the system stores and looks up the values through their unique identifiers.
     
     - Tag: query_by_id
     */
    func entities(for identifiers: [TrailEntity.ID]) async throws -> [TrailEntity] {
        Logger.entityQueryLogging.debug("[TrailEntityQuery] Query for IDs \(identifiers)")
        
        return trailManager.trails(with: identifiers)
                .map { TrailEntity(trail: $0) }
    }
    
    /**
     - Returns: The most likely choices relevant to the individual, such as the contents of a favorites list. The system displays these values as
     a list of options for the entities. For example, configuring the Get Trail Info intent in the Shortcuts app will show these values
     as suggestions for the trail parameter.
     
     - Tag: suggested_entities
     */
    func suggestedEntities() async throws -> [TrailEntity] {
        Logger.entityQueryLogging.debug("[TrailEntityQuery] Request for suggested entities")
        
        return trailManager.trails(with: trailManager.favoritesCollection.members)
                .map { TrailEntity(trail: $0) }
    }
}

/// An `EntityStringQuery` extends the capability of an `EntityQuery` by allowing people to search for an entity with a string.
extension TrailEntityQuery: EntityStringQuery {
    
    /**
     To see this method, configure the Get Trail Info intent in the Shortcuts app. A list displays the suggested entities.
     If you search for an entity not in the suggested entities list, the system passes the search string to this method.
     
     - Tag: string_query
     */
    func entities(matching string: String) async throws -> [TrailEntity] {
        Logger.entityQueryLogging.debug("[TrailEntityQuery] String query for term \(string)")
        
        return trailManager.trails { trail in
            trail.name.localizedCaseInsensitiveContains(string)
        }.map { TrailEntity(trail: $0) }
    }
}
