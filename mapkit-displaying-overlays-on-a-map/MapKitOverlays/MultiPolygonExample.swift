/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example showing how to create a multipolygon from a GeoJSON overlay and render it on the map with a single renderer.
*/

import Foundation
import MapKit

extension OverlayViewController {
 
    func displayMultiPolygonExample() {
        title = "Multipolygon Renderer"
        
        let eventData = EventDataSource()
        
        mapView.register(EventAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.addAnnotations(eventData.annotations)
        
        mapView.addOverlays(eventData.overlays)
        
        if let firstOverlay = eventData.overlays.first {
            /// Focus the map on the overlay, adding space around the edges to frame it nicely within the view controller's view.
            mapView.setVisibleMapRect(firstOverlay.boundingMapRect, edgePadding: standardPadding, animated: false)
            
            /**
             To make sure users don't accidentally pan away from the event and get lost, apply a camera boundary. This ensures that the
             center point of the map always remains inside this region.
             */
            let cameraBoundary = MKCoordinateRegion(center: firstOverlay.coordinate, latitudinalMeters: 100, longitudinalMeters: 80)
            mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: cameraBoundary)
        }
        
        /// To remove information that interferes with the event map, turn off all points of interest using an `excludingAll` filter.
        mapView.pointOfInterestFilter = .excludingAll
        
        /**
         There's no reason for users to zoom out to view all of California and beyond, nor does the event map have enough details to make
         detailed zoom levels relevant. Apply a camera zoom range to restrict how far in and out users can zoom in the map view.
        */
        mapView.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 250, maxCenterCoordinateDistance: 800)
    }
    
    /// - Tag: multipolygon_renderer
    /**
     An `MKMultiPolygon` represents multiple polygons that all render using the same visual style, lowering the number of
     required individual rendering objects. If a map is displaying numerous overlays that all need the same style, grouping the
     polygons into an `MKMultiPolygon` improves performance over rendering each polygon with its own renderer object.
    */
    func createMultiPolylineRenderer(for multiPolygon: MKMultiPolygon) -> MKMultiPolygonRenderer {
        let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
        renderer.fillColor = UIColor(named: "MultiPolygonOverlayFill")
        renderer.strokeColor = UIColor(named: "MultiPolygonOverlayStroke")
        renderer.lineWidth = 2.0

        return renderer
    }
}
