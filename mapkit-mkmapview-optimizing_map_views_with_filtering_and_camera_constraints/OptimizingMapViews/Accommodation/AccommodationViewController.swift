/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller responsible for the accommodation view.
*/

import UIKit
import MapKit

/// This class displays annotations from its data source on a map view.
class AccommodationViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet private var mapView: MKMapView!

    private let dataSource: AccommodationDataSource

    required init?(coder: NSCoder) {
        dataSource = AccommodationDataSource()
        super.init(coder: coder)

        title = "Accommodation"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        /*
         The accommodation feature displays partner hotels as annotations on the
         map. To ensure that competitor hotels are not showing up as points of
         interest in the map, apply an inclusion filter to show only points of
         interest from the desired categories: Restaurant, Cafe, Parking and
         Nightlife.
        */
        mapView.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .parking, .nightlife])

        mapView.addAnnotations(dataSource.annotations)
        mapView.showAnnotations(dataSource.annotations, animated: false)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier:
                                                                      MKMapViewDefaultAnnotationViewReuseIdentifier,
                                                                      for: annotation) as? MKMarkerAnnotationView {
            if annotation is MKPointAnnotation {
                annotationView.glyphText = "H"
                annotationView.markerTintColor = nil
            }

            return annotationView
        }

        return nil
    }
}
