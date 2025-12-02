/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class is the data source for the event view.
*/

import UIKit
import MapKit

class EventDataSource {

    var overlays: [MKOverlay]
    var annotations: [MKAnnotation]

    init() {
        overlays = [MKOverlay]()
        annotations = [MKAnnotation]()

        /*
         In a real app, the event data would probably be downloaded from a
         server. This sample loads GeoJSON data from a locally bundled file
         instead.
        */
        if let jsonUrl = Bundle.main.url(forResource: "event", withExtension: "json") {
            do {
                let eventData = try Data(contentsOf: jsonUrl)

                /*
                 Use the MKGeoJSONDecoder to convert the JSON data into MapKit
                 objects, such as MKGeoJSONFeature.
                */
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

            /*
             In this sample's GeoJSON data there are only features in the
             top-level so this parse method only checks for those. In a generic
             parser, check for geometry objects here too.
            */
            if let feature = object as? MKGeoJSONFeature {
                for geometry in feature.geometry {

                    /*
                     Separate out annotation objects from overlay objects
                     because they are added to the map view in different ways.
                     This sample GeoJSON only contains points and multipolygon
                     geometry. In a generic parser, check for all possible
                     geometry types.
                    */
                    if let multiPolygon = geometry as? MKMultiPolygon {
                        overlays.append(multiPolygon)
                    } else if let point = geometry as? MKPointAnnotation {

                        /*
                         The name of the annotation is passed in the feature
                         properties. Parse the name and apply it to the
                         annotation.
                        */
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

        /*
         GeoJSON does not dictate the format of the 'properties' member. It
         may be any valid JSON, or 'null'. Depending on how the GeoJSON is
         structured take one of the following approaches:

         If you know the format of the properties data, map it to a suitable model object
         using Swift's JSONDecoder.

         If you don't know the structure of the data, use the JSONSerialization API
         to dynamically explore the contents of the data.

         This sample uses the JSONDecoder API approach.
        */
        let decoder = JSONDecoder()
        if let dictionary = try? decoder.decode([String: String].self, from: properties) {
            annotation.title = dictionary["name"]
        }
    }
}
