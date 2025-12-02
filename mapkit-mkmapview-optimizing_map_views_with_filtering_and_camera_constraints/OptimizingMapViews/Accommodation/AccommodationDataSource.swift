/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class is the data source for the accommodation view.
*/

import UIKit
import MapKit

class AccommodationDataSource {

    let annotations: [MKAnnotation]

    init() {
        var annotations = [MKAnnotation]()

        /*
         For the sake of simplicity of the sample code the accommodation
         locations are declared in this file. In a real application this data
         would probably be downloaded from a server instead.
        */
        var annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 37.331_486, longitude: -121.882_607)
        annotation.title = "Lumpy Lumbar Slumber"
        annotation.subtitle = "Save $$$ - Only $20 per night for attendees"
        annotations.append(annotation)

        annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 37.332_704, longitude: -121.887_640)
        annotation.title = "Coder’s Dream Inn"
        annotation.subtitle = "Save $50 per night"
        annotations.append(annotation)

        annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 37.328_335, longitude: -121.886_598)
        annotation.title = "Hacker Hidey Hole"
        annotation.subtitle = "Tiny but cheap!"
        annotations.append(annotation)

        annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 37.336_770, longitude: -121.891_271)
        annotation.title = "Hay Bale Beds Barn"
        annotation.subtitle = "Save $$"
        annotations.append(annotation)

        annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 37.329_942, longitude: -121.881_415)
        annotation.title = "Solid Slab Stayover"
        annotation.subtitle = "It does not get cheaper than this! $10/night"
        annotations.append(annotation)

        self.annotations = annotations
    }
}
