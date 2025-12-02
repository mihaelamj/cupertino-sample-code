/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example showing how to create a circle overlay and render it on the map.
*/

import Foundation
import MapKit

extension OverlayViewController {
    
    /// - Tag: circle
    func displayCircleExample() {
        title = "Circle"
        
        /// Create a circle overlay that centers on San Francisco.
        let circleOverlay = MKCircle(center: LocationData.sanFranciscoGeographicCenter, radius: 9000)
        mapView.addOverlay(circleOverlay, level: overlayLevel)
        
        /// Focus the map on the overlay, adding space around the edges to frame it nicely within the view controller's view.
        mapView.setVisibleMapRect(circleOverlay.boundingMapRect, edgePadding: standardPadding, animated: false)
    }
    
    /// - Tag: circle_renderer
    func createCircleRenderer(for circle: MKCircle) -> MKCircleRenderer {
        /**
         Some of the most common customizations for an `MKOverlayRenderer` include customizing drawing settings, such as the
         fill color of an enclosed shape, or the stroke color for the edge of the shape.
         */
        let renderer = MKCircleRenderer(circle: circle)
        renderer.lineWidth = 2
        renderer.strokeColor = .systemBlue
        renderer.fillColor = .systemTeal
        renderer.alpha = 0.5
        
        return renderer
    }
}
