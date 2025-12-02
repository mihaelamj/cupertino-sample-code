/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object for querying the app's trail data.
*/

import CoreLocation
import Foundation
import Observation

@Observable class TrailDataManager: @unchecked Sendable {
    
    static let shared = TrailDataManager()

    /// An array of all the trails in the app.
    let trails: [Trail]
    
    /// An array of trail collections containing the featured trail groups, representing a section in `SidebarColumn`.
    let featuredTrailCollections: [TrailCollection]
    
    /// The trail collections in the For You group of `SidebarColumn`, including favorite trails and those close to the individual.
    let forYouCollections: [TrailCollection]
    
    /// A trail collection containing the individual's favorite trails.
    let favoritesCollection: TrailCollection
    
    /// A trail collection containing trails that are close to the individual.
    let nearMeCollection: TrailCollection
    
    /// A trail collection containing all of the trails in the `trails` property.
    let completeTrailCollection: TrailCollection
    
    private init() {
        guard let dataURL = Bundle.main.url(forResource: "TrailData", withExtension: "plist") else {
            fatalError("Could not locate data file.")
        }
        
        var dataContainer: DataContainer!
        do {
            let data = try Data(contentsOf: dataURL)
            let decoder = PropertyListDecoder()
            dataContainer = try decoder.decode(DataContainer.self, from: data)
        } catch let error {
            fatalError("Could not decode data. Error: \(error)")
        }
                
        // Pretends the individual is at Apple Park, and calculates the distance to the trail from there.
        let applePark = CLLocation(latitude: 37.334_59, longitude: -122.008_89)
        let configuredTrails = dataContainer.trails.map { trailDetails in
            let trailLocation = CLLocation(latitude: trailDetails.latitude, longitude: trailDetails.longitude)
            let distance = trailLocation.distance(from: applePark)
            return Trail(data: trailDetails, travelDistance: distance)
        }
        
        let completeTrailList = TrailCollection(id: 2,
                                                collectionType: .browseTrails,
                                                name: "Browse",
                                                symbolName: "figure.hiking",
                                                members: configuredTrails.map { $0.id })
        
        // Finds trails within 100 km of the individual's location, which is Apple Park.
        let nearMeTrailIDs = configuredTrails.filter { trail in
            trail.distanceToTrail.value <= 100 * 1000 // 100 km
        }.map { $0.id }
        let nearMe = TrailCollection(id: 3,
                                     collectionType: .nearMe,
                                     name: "Near Me",
                                     symbolName: "location.magnifyingglass",
                                     members: nearMeTrailIDs)
        
        let favorites = dataContainer.collections.first(where: { $0.collectionType == .favorites })!
        forYouCollections = [nearMe, favorites, completeTrailList]
        
        favoritesCollection = favorites
        nearMeCollection = nearMe
        completeTrailCollection = completeTrailList
        
        trails = configuredTrails
        featuredTrailCollections = dataContainer.collections.filter { $0.collectionType == .featured }
        
    #if canImport(CoreSpotlight)
        Task {
            await updateSpotlightIndex()
        }
    #endif
    }
}

/// This extension contains the public query API to find specific trails.
extension TrailDataManager {
    
    /// - Returns: The `Trail` with `identifier`, or `nil` if the system doesn't find a match.
    func trail(with identifier: Trail.ID) -> Trail? {
        return trails.first { $0.id == identifier }
    }
    
    /// - Returns: An array of `Trail` structures with the requested `identifiers`.
    func trails(with identifiers: [Trail.ID]) -> [Trail] {
        return trails.compactMap { trail in
            return identifiers.contains(trail.id) ? trail : nil
        }
    }
    
    /// - Returns: An array of `Trail` structures that the `predicate` closure returns.
    func trails(matching predicate: (Trail) -> Bool) -> [Trail] {
        return trails.filter(predicate)
    }
    
    /// - Returns: A set of unique location names for all the trails in the data set.
    var uniqueLocations: Set<String> {
        let locationList = trails.compactMap { $0.regionDescription }
        
        // Remove duplicate locations by running the values through a `Set` operation.
        let dedupedLocations = Set(locationList)
        return dedupedLocations
    }
}
