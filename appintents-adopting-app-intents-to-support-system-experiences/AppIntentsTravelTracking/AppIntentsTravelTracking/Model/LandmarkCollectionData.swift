/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import Foundation

extension Collection {
    @MainActor static let exampleData = [
        Collection(
            id: 1001,
            name: String(localized: .LandmarkCollectionData.favoritesName),
            description: "",
            landmarkIds: [1001, 1021, 1007, 1012],
            landmarks: []
        ),

        Collection(
            id: 1002,
            name: String(localized: .LandmarkCollectionData.toweringPeaksName),
            description: String(localized: .LandmarkCollectionData.toweringPeaksDescription),
            landmarkIds: [1016, 1018, 1007, 1022],
            landmarks: []
        ),
        
        Collection(
            id: 1003,
            name: String(localized: .LandmarkCollectionData._2023TripName),
            description: String(localized: .LandmarkCollectionData._2023TripDescription),
            landmarkIds: [1005],
            landmarks: []
        ),
        
        Collection(
            id: 1004,
            name: String(localized: .LandmarkCollectionData.sweetDesertsName),
            description: String(localized: .LandmarkCollectionData.sweetDesertsDescription),
            landmarkIds: [1006, 1001, 1008],
            landmarks: []
        ),
        
        Collection(
            id: 1005,
            name: String(localized: .LandmarkCollectionData.icyWonderlandName),
            description: String(localized: .LandmarkCollectionData.icyWonderlandDescription),
            landmarkIds: [],
            landmarks: []
        )
    ]
}
