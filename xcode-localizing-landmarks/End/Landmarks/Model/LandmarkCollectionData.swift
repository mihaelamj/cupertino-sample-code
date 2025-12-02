/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's sample collection data.
*/

import Foundation

extension LandmarkCollection {
    /// The app's sample collection data.
    @MainActor static let exampleData = [
        LandmarkCollection(
            id: 1001,
            name: String(localized: "Favorites", table: "LandmarkCollectionData"),
            description: "",
            landmarkIds: [1001, 1021, 1007, 1012],
            landmarks: []
        ),
        
        LandmarkCollection(
            id: 1002,
            name: String(localized: "Towering Peaks", table: "LandmarkCollectionData"),
            description: String(localized: "Gorgeous mountain peaks!", table: "LandmarkCollectionData"),
            landmarkIds: [1016, 1018, 1007, 1022],
            landmarks: []
        ),
        
        LandmarkCollection(
            id: 1003,
            name: String(localized: "2023 Trip", table: "LandmarkCollectionData"),
            description: String(localized: "Places we visited on our great trip in 2023.", table: "LandmarkCollectionData"),
            landmarkIds: [],
            landmarks: []
        ),
        
        LandmarkCollection(
            id: 1004,
            name: String(localized: "Sweet Deserts", table: "LandmarkCollectionData"),
            description: String(localized: "Spectacular deserts around the world.", table: "LandmarkCollectionData"),
            landmarkIds: [1006, 1001, 1008],
            landmarks: []
        ),
        
        LandmarkCollection(
            id: 1005,
            name: String(localized: "Icy Wonderland", table: "LandmarkCollectionData"),
            description: String(localized: "They’re chilly, but amazing!", table: "LandmarkCollectionData"),
            landmarkIds: [],
            landmarks: []
        )
    ]
}
