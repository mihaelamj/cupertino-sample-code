/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Load and parse earthquake data via a feature collection.
*/

import SwiftData
import OSLog

// A mapping from items in the feature collection to earthquake items.
extension Quake {
    /// Creates a new quake instance from a decoded feature.
    convenience init(from feature: GeoFeatureCollection.Feature) {
        self.init(
            code: feature.properties.code,
            magnitude: feature.properties.mag,
            time: feature.properties.time,
            name: feature.properties.place,
            longitude: feature.geometry.coordinates[0],
            latitude: feature.geometry.coordinates[1]
        )
    }
}

// Helper methods for loading feature data and storing it as quakes.
extension GeoFeatureCollection {
    /// A logger for debugging.
    fileprivate static let logger = Logger(subsystem: "com.example.apple-samplecode.DataCache", category: "parsing")

    /// Loads new earthquakes and deletes outdated ones.
    @MainActor
    static func refresh(modelContext: ModelContext) async {
        do {
            // Fetch the latest set of quakes from the server.
            logger.debug("Refreshing the data store...")
            let featureCollection = try await fetchFeatures()
            logger.debug("Loaded feature collection:\n\(featureCollection)")

            // Add the content to the data store.
            for feature in featureCollection.features {
                let quake = Quake(from: feature)

                // Ignore anything with a magnitude of zero or less.
                if quake.magnitude > 0 {
                    logger.debug("Inserting \(quake)")
                    modelContext.insert(quake)
                }
            }

            logger.debug("Refresh complete.")

        } catch let error {
            logger.error("\(error.localizedDescription)")
        }
    }
}
