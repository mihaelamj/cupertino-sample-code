/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This class is the data source for the event view.
*/

import UIKit
import MapKit

class EventDataSource {

    private(set) var overlays = [MKOverlay]()
    private(set) var annotations = [MKAnnotation]()

    /// - Tag: geojson_parse
    init() {
        /// In a real app, the event data probably downloads from a server. This sample loads GeoJSON data from a local file instead.
        if let jsonUrl = Bundle.main.url(forResource: "event", withExtension: "json") {
            do {
                let eventData = try Data(contentsOf: jsonUrl)

                // Use the `MKGeoJSONDecoder` to convert the JSON data into MapKit objects, such as `MKGeoJSONFeature`.
                let decoder = MKGeoJSONDecoder()
                let jsonObjects = try decoder.decode(eventData)

                parse(jsonObjects)
            } catch {
                print("Error decoding GeoJSON: \(error).")
            }
        }
    }

    private func parse(_ jsonObjects: [MKGeoJSONObject]) {
        for object in jsonObjects {

            /**
             In this sample's GeoJSON data, there are only GeoJSON features at the top level, so this parse method only checks for those. An
             implementation that parses arbitrary GeoJSON files needs to check for GeoJSON geometry objects too.
            */
            if let feature = object as? MKGeoJSONFeature {
                for geometry in feature.geometry {

                    /**
                     Separate annotation objects from overlay objects because you add them to the map view in different ways. This sample
                     GeoJSON only contains `Point` and `MultiPolygon` geometry. In a generic parser, check for all possible geometry types.
                    */
                    if let multiPolygon = geometry as? MKMultiPolygon {
                        overlays.append(multiPolygon)
                    } else if let point = geometry as? MKPointAnnotation {
                         // The name of the annotation passes in the feature properties.
                         // Parse the name and apply it to the annotation.
                        configure(annotation: point, using: feature.properties)
                        annotations.append(point)
                    }
                }
            }
        }
    }

    private func configure(annotation: MKPointAnnotation, using properties: Data?) {
        guard let properties = properties else {
            return
        }

        /**
         GeoJSON doesn't dictate the format of the 'properties' member. It may be any valid JSON, or 'null'. Depending on the structure of
         the GeoJSON, take one of the following approaches:
         * If you know the format of the properties data, map it to a suitable model object using `JSONDecoder`.
         * If you don't know the structure of the data, use `JSONSerialization` to dynamically explore the data.

         This sample uses the `JSONDecoder` approach.
        */
        let decoder = JSONDecoder()
        if let dictionary = try? decoder.decode([String: String].self, from: properties) {
            annotation.title = dictionary["name"]
        }
    }
}
