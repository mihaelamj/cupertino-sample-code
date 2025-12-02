/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extension on `AppModel` to load all assets.
*/

import SwiftUI
import RealityKit
import RealityKitContent

extension AppModel {
    
    /// Asynchronously loads assets while the app starts up.
    func prepareAssets() async throws {
        defer { doAllSetup() }
        // Load the root entity, the Grand Canyon scene.
        async let rootScene = try await Entity(named: EntityName.grandCanyonScene.rawValue, in: realityKitContentBundle)
        root = try await rootScene
        
        grandCanyonEntity = try await root.findAndLoadEntity(named: .grandCanyonEntity, error: .grandCanyon)
        
        let terrainEntity = try await self.grandCanyonEntity.findAndLoadEntity(named: .terrain, error: .terrain)
        self.terrainEntityBaseExtents = (terrainEntity.visualBounds(relativeTo: nil).extents) / terrainEntity.scale(relativeTo: nil)
        
        sunlight = try await root.findAndLoadEntity(named: .sunlight, error: .sunlight)
        
        birdsEntity = try await root.findAndLoadEntity(named: .birds, error: .birds)
     
        cloudsEntity = try await grandCanyonEntity.findAndLoadEntity(named: .clouds, error: .clouds)
        
        hikerEntity = try await grandCanyonEntity.findAndLoadEntity(named: .hiker, error: .hiker)
        
        hikeEntities = hikes.reduce(into: [Hike: [Entity]]()) { partialResult, hike in
            partialResult[hike] = []
        }
        await loadHikeAssets()
    }
    
    /// Loads the hike and rest stop entities asynchronously.
    func loadHikeAssets() async {
        for hike in hikes {
            async let hikeEntity = self.grandCanyonEntity.childAt(path: hike.trailEntityPath)
            if let hikeEntity = await hikeEntity {
                hikeEntity.isEnabled = false
                hikeEntities[hike]?.append(hikeEntity)
            }
            for restStop in hike.restStops {
                async let restStopEntity = self.grandCanyonEntity.findEntity(named: restStop.entityName)
                if let restStopEntity = await restStopEntity {
                    hikeEntities[hike]?.append(restStopEntity)
                }
            }
        }
    }
}
