/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Enables a Find intent for locating trails through predicate queries in the Shortcuts app.
*/

@preconcurrency import AppIntents
import Foundation
import OSLog

/**
 An `EntityPropertyQuery` queries entities by matching values against one or more of their properties. Conforming an entity query to
 `EntityPropertyQuery` automatically adds a Find intent to the list of intents in the Shortcuts app, providing UI to build complex predicates beyond
 the capabilities of `EntityStringQuery`.
 */
extension TrailEntityQuery: EntityPropertyQuery {
    
    /**
     The type of the comparator to use for the property query. This sample uses `Predicate`, but other apps could use `NSPredicate` (for
     Core Data) or an entirely custom comparator that works with an existing data model.
     */
    typealias ComparatorMappingType = Predicate<TrailEntity>
    
    /**
     Declare the entity properties that are available for queries and in the Find intent, along with the comparator the app uses when querying the
     property.
     */
    static let properties = QueryProperties {
        Property(\TrailEntity.$name) {
            ContainsComparator { searchValue in
                #Predicate<TrailEntity> { $0.name.localizedStandardContains(searchValue) }
            }
            EqualToComparator { searchValue in
                #Predicate<TrailEntity> { $0.name == searchValue }
            }
            NotEqualToComparator { searchValue in
                #Predicate<TrailEntity> { $0.name != searchValue }
            }
        }
        
        Property(\TrailEntity.$trailLength) {
            LessThanOrEqualToComparator { searchValue in
                #Predicate<TrailEntity> { entity in
                    entity.trailLength <= searchValue
                }
            }
            GreaterThanOrEqualToComparator { searchValue in
                #Predicate<TrailEntity> { entity in
                    entity.trailLength >= searchValue
                }
            }
        }
    }
    
    /// Declare the entity properties available as sort criteria in the Find intent.
    static let sortingOptions = SortingOptions {
        SortableBy(\TrailEntity.$name)
        SortableBy(\TrailEntity.$trailLength)
    }
    
    /// The text that people see in the Shortcuts app, describing what this intent does.
    static var findIntentDescription: IntentDescription? {
        IntentDescription("Search for the best trails matching your interest based on complex criteria.",
                          categoryName: "Discover",
                          searchKeywords: ["trail", "location", "travel"],
                          resultValueName: "Trails")
    }

    /// Performs the Find intent using the predicates that the individual enters in the Shortcuts app.
    func entities(matching comparators: [Predicate<TrailEntity>],
                  mode: ComparatorMode,
                  sortedBy: [EntityQuerySort<TrailEntity>],
                  limit: Int?) async throws -> [TrailEntity] {
        
        Logger.entityQueryLogging.debug("[TrailEntityQuery] Property query started")
        
        /// Get the trail entities that meet the criteria of the comparators.
        var matchedTrails = try trails(matching: comparators, mode: mode)

        /**
         Apply the requested sort. `EntityQuerySort` specifies the value to sort by using a `PartialKeyPath`. This key path builds a
         `KeyPathComparator` to use default sorting implementations for the value that the key path provides. For example, this approach uses
         `SortComparator.localizedStandard` when sorting key paths with a `String` value.
         */
        Logger.entityQueryLogging.debug("[TrailEntityQuery] Sorting results")
        for sortOperation in sortedBy {
            switch sortOperation.by {
            case \.$name:
                matchedTrails.sort(using: KeyPathComparator(\TrailEntity.name, order: sortOperation.order.sortOrder))
            case \.$trailLength:
                matchedTrails.sort(using: KeyPathComparator(\TrailEntity.trailLength, order: sortOperation.order.sortOrder))
            default:
                break
            }
        }
        
        /**
         People can optionally customize a limit to the number of results that a query returns.
         If your data model supports query limits, you can also use the limit parameter when querying
         your data model, to allow for faster searches.
         */
        if let limit, matchedTrails.count > limit {
            Logger.entityQueryLogging.debug("[TrailEntityQuery] Limiting results to \(limit)")
            matchedTrails.removeLast(matchedTrails.count - limit)
        }
        
        Logger.entityQueryLogging.debug("[TrailEntityQuery] Property query complete")
        return matchedTrails
    }
    
    /// - Returns: The trail entities that meet the criteria of `comparators` and `mode`.
    private func trails(matching comparators: [Predicate<TrailEntity>], mode: ComparatorMode) throws -> [TrailEntity] {
        try trailManager.trails.compactMap { trail in
            let entity = TrailEntity(trail: trail)
            
            /**
             For an AND search (criteria1 AND criteria2 AND ...), this variable starts as `true`.
             If any of the comparators don't match, the app sets it to `false`, allowing the comparator loop to break early because a comparator
             doesn't satisfy the AND requirement.
             
             For an OR search (criteria1 OR criteria2 OR ...), this variable starts as `false`.
             If any of the comparators match, the app sets it to `true`, allowing the comparator loop to break early because any comparator that
             matches satisfies the OR requirement.
             */
            var includeAsResult = mode == .and ? true : false
            let earlyBreakCondition = includeAsResult
            Logger.entityQueryLogging.debug("[TrailEntityQuery] Starting to evaluate predicates for \(trail.name)")
            for comparator in comparators {
                guard includeAsResult == earlyBreakCondition else {
                    Logger.entityQueryLogging.debug("[TrailEntityQuery] Predicates matched? \(includeAsResult)")
                    break
                }
                
                /// Runs the `Predicate` expression with the specific `TrailEntity` to determine whether the entity matches the conditions.
                includeAsResult = try comparator.evaluate(entity)
            }
            
            Logger.entityQueryLogging.debug("[TrailEntityQuery] Predicates matched? \(includeAsResult)")
            return includeAsResult ? entity : nil
        }
    }
}

extension EntityQuerySort.Ordering {
    /// Convert sort information from `EntityQuerySort` to  Foundation's `SortOrder`.
    var sortOrder: SortOrder {
        switch self {
        case .ascending:
            return SortOrder.forward
        case .descending:
            return SortOrder.reverse
        }
    }
}
