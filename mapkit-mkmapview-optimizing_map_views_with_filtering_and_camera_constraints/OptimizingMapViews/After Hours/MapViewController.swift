/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller responsible for displaying search results on a map view.
*/

import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet private var mapView: MKMapView!

    private var annotations = [MKAnnotation]()

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.region = .afterHours
    }

    func show(mapItems: [MKMapItem]) {
        mapView.removeAnnotations(annotations)

        if !mapItems.isEmpty {
            /*
             MKMapItem doesn't conform to the MKAnnotation protocol, so map
             items can't be added directly to the map view. Instead, create
             instances of MKPointAnnotation and populate them with the data
             from the map items.
            */
            annotations = mapItems.map { mapItem in
                let annotation = MKPointAnnotation()
                annotation.coordinate = mapItem.placemark.coordinate
                annotation.title = mapItem.placemark.name
                annotation.subtitle = mapItem.placemark.title
                return annotation
            }

            mapView.addAnnotations(annotations)
            mapView.showAnnotations(annotations, animated: true)
        } else {
            annotations = []
        }
    }
}
