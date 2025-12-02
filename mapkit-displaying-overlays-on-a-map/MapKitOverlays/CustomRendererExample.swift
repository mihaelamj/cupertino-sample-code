/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example showing how to create a custom overlay and render it on the map with a custom renderer.
*/

import Foundation
import MapKit

extension OverlayViewController {
 
    func displayCustomRendererExample() {
        title = "Custom Renderer"
        
        Task {
            /**
             This data file is part of the "2008 National Seismic Hazard Model for the Conterminous U.S.", published
             by the United States Geological Survey at `https://www.sciencebase.gov/catalog/item/5db892f2e4b0b0c58b5a51b6`.
             */
            let dataURL = Bundle.main.url(forResource: "2008.US.0p00.760.975", withExtension: "txt")!
            if let hazards = await PeakGroundAccelerationGrid(gridedDataFile: dataURL) {
                mapView.addOverlay(hazards, level: overlayLevel)
                
                /**
                 Display the full region with the custom data rendering with a 100 km outset so the edges of the custom rendering area are visible,
                 rather than being right at the edge of the map view.
                 */
                var rectForDisplay = hazards.boundingMapRect
                let outsetAmount = MKMapPointsPerMeterAtLatitude(hazards.coordinate.latitude) * 100_000
                rectForDisplay = rectForDisplay.insetBy(dx: -outsetAmount, dy: -outsetAmount)
                mapView.setVisibleMapRect(rectForDisplay, animated: true)
            }
        }
    }
    
    func createCustomRenderer(for overlay: PeakGroundAccelerationGrid) -> MKOverlayRenderer {
        return PeakGroundAccelerationOverlayRenderer(overlay: overlay)
    }
}
