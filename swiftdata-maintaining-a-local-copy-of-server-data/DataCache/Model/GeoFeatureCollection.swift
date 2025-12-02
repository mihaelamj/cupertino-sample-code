/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of the JSON data served by the USGS server.
*/

import Foundation

/// A container that decodes a feature collection from the server.
///
/// This structure decodes JSON with the following layout:
///
/// ```json
/// {
///    "features": [
///          {
///       "properties": {
///         "mag": 1.9,
///         "place": "21km ENE of Honaunau-Napoopoo, Hawaii",
///         "time": 1539187727610,
///         "code": "70643082"
///       },
///       "gemoetry": {
///         "coordinates": [63.2, -150.9, 5.2]
///       }
///     }
///   ]
/// }
/// ```
///
struct GeoFeatureCollection: Decodable {
    let features: [Feature]

    struct Feature: Decodable {
        let properties: Properties
        let geometry: Geometry
        
        struct Properties: Decodable {
            let mag: Double
            let place: String
            let time: Date
            let code: String
        }

        struct Geometry: Decodable {
            let coordinates: [Double]
        }
    }
}

extension GeoFeatureCollection.Feature: CustomStringConvertible {
    var description: String {
    """
    feature: {
        properties: {
            mag: \(properties.mag),
            place: \(properties.place),
            time: \(properties.time),
            code: \(properties.code)
        },
        geometry: { coordinates: \(geometry.coordinates) }
    }
    """
    }
}

extension GeoFeatureCollection: CustomStringConvertible {
    var description: String {
        var description = "Empty feature collection."
        if let feature = features.first {
            description = feature.description
            if features.count > 1 {
                description += "\n...and \(features.count - 1) more."
            }
        }
        return description
    }
}

// Fetch new data.
extension GeoFeatureCollection {
    /// Gets and decodes the latest earthquake data from the server.
    static func fetchFeatures() async throws -> GeoFeatureCollection {
        /// Geological data provided by the U.S. Geological Survey (USGS). See ACKNOWLEDGMENTS.txt for additional details.
        let url = URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson")!

        let session = URLSession.shared
        guard let (data, response) = try? await session.data(from: url),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw DownloadError.missingData
        }

        do {
            // Decode the GeoJSON into a data model.
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
            return try jsonDecoder.decode(GeoFeatureCollection.self, from: data)
        } catch {
            throw DownloadError.wrongDataFormat(error: error)
        }
    }
}

/// The kinds of errors that occur when loading feature data.
enum DownloadError: Error {
    case wrongDataFormat(error: Error)
    case missingData
}
