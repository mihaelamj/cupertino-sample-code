/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller responsible for the event view.
*/

import UIKit
import MapKit

/**
 This class displays overlays and annotations loaded from its data source on a
 map view.
*/
class EventViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet private var mapView: MKMapView!

    private let dataSource: EventDataSource

    required init?(coder: NSCoder) {
        dataSource = EventDataSource()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.region = .event

        /*
         To remove clutter that interferes with the event map, turn
         off all points of interest using an excludingAll filter.
        */
        mapView.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll

        /*
         To make sure users do not accidentally pan away from the event and get
         lost, apply a camera boundary. This ensures that the center point of
         the map always remain inside this region.
        */
        mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: .cameraBoundary)

        /*
         There is no reason for users to zoom out to view all of California and
         beyond, nor does the event map have enough details to make detailed
         zoom levels relevant. Apply a camera zoom range to restrict how far in
         and out users can zoom in the map view.
        */
        mapView.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 250,
                                                            maxCenterCoordinateDistance: 800)

        mapView.register(EventAnnotationView.self, forAnnotationViewWithReuseIdentifier:
                                                   MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.addAnnotations(dataSource.annotations)
        mapView.addOverlays(dataSource.overlays)
    }

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if let multiPolygon = overlay as? MKMultiPolygon {
            let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
            renderer.fillColor = UIColor(named: "OverlayFill")
            renderer.strokeColor = UIColor(named: "OverlayStroke")
            renderer.lineWidth = 2.0

            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }
}
