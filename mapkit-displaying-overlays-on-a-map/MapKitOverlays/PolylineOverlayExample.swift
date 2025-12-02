/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example showing how to create different types of polyline overlays and render them on the map.
*/

import Foundation
import MapKit

extension OverlayViewController {
    
    // MARK: Polyline Definitions
    
    /// Creates a basic polyline with two locations, a start and an end point.
    var simplePolyline: MKPolyline {
        return MKPolyline(coordinates: LocationData.sanFranciscoBridgeAndPark, count: LocationData.sanFranciscoBridgeAndPark.count)
    }
    
    /// Creates a polyline with multiple locations. The specific order of locations means the polyline crosses itself.
    var crossedPolyline: MKPolyline {
        return MKPolyline(coordinates: LocationData.crossedSanFranciscoLocations, count: LocationData.crossedSanFranciscoLocations.count)
    }
    
    // MARK: Standard Polyline
    
    func displayPolylineExample() {
        title = "Polyline"
        
        // Display a polyline with a single line segment between two points.
        mapView.addOverlay(simplePolyline, level: overlayLevel)
        
        // Display a polyline with multiple segments that cross each other.
        mapView.addOverlay(crossedPolyline, level: overlayLevel)
        
        /// Focus the map on the overlay, adding space around the edges to frame it nicely within the view controller's view.
        mapView.setVisibleMapRect(crossedPolyline.boundingMapRect, edgePadding: standardPadding, animated: false)
    }
    
    /// - Tag: line_dash_pattern
    func createPolylineRenderer(for line: MKPolyline) -> MKPolylineRenderer {
        let renderer = MKPolylineRenderer(polyline: line)
        
        if line.coordinates == LocationData.sanFranciscoBridgeAndPark {
            renderer.strokeColor = .systemPink
            renderer.lineWidth = 8
            
        } else if line.coordinates == LocationData.crossedSanFranciscoLocations {
            renderer.strokeColor = .systemTeal
            renderer.lineWidth = 2
            
            /**
             Apply a custom pattern to the line, alternating dash length with space length in drawing points.
             The pattern repeats for the length of the polyline.
             */
            renderer.lineDashPattern = [20 as NSNumber,   // Long dash
                                        10 as NSNumber,   // Space
                                         5 as NSNumber,   // Shorter dash
                                        10 as NSNumber,   // Space
                                         1 as NSNumber,   // Dot
                                        10 as NSNumber]   // Space
        } else {
            renderer.strokeColor = .tintColor
            renderer.lineWidth = 2
        }
        
        return renderer
    }
    
    // MARK: Geodesic Polyline
    
    func displayGeodesicPolylineExample() {
        title = "Geodesic Polyline"
        
        /**
         A geodesic polyline follows the shortest path between two points, following the Earth's surface.
         As a result of following the Earth's surface, the polyline may appear curved, especially over long distances within the same hemisphere,
         as this example shows.
         */
        let geodesicLocations = [LocationData.sanFranciscoCivicCenter, LocationData.paris]
        let geodesicPolyline = MKGeodesicPolyline(coordinates: geodesicLocations, count: geodesicLocations.count)
        
        mapView.addOverlay(geodesicPolyline, level: overlayLevel)
        
        /// Focus the map on the overlay, adding space around the edges to frame it nicely within the view controller's view.
        mapView.setVisibleMapRect(geodesicPolyline.boundingMapRect, edgePadding: standardPadding, animated: false)
    }
    
    func createGeodesicPolylineRenderer(for line: MKPolyline) -> MKPolylineRenderer {
         /// You render an `MKGeodesicPolyline`  the same way as `MKPolyline`, by using either `MKPolylineRenderer` or `MKGradientPolylineRenderer`.
        let renderer = MKPolylineRenderer(polyline: line)
        renderer.strokeColor = .tintColor
        renderer.lineWidth = 8
        
        return renderer
    }
    
    // MARK: Gradient Polyline
    
    func displayGradientPolylineExample() {
        title = "Gradient Polyline"
        
        /**
         A gradient polyline is an `MKPolyline` that uses an `MKGradientPolylineRenderer` to configure the gradient colors.
         You create the renderer in the `MKMapViewDelegate` implementation of `mapView(_:rendererFor:)`.
         */
        mapView.addOverlay(crossedPolyline, level: overlayLevel)
        
        /// Focus the map on the overlay, adding space around the edges to frame it nicely within the view controller's view.
        mapView.setVisibleMapRect(crossedPolyline.boundingMapRect, edgePadding: standardPadding, animated: false)
    }
    
    /// - Tag: gradient_renderer
    func createGradientPolylineRenderer(for line: MKPolyline) -> MKGradientPolylineRenderer {
        let renderer = MKGradientPolylineRenderer(polyline: line)
        
        let colorPalette: [UIColor] = [.systemPurple, .systemMint, .systemOrange, .systemTeal, .systemRed]
        
        /**
         Gradient polylines take an array of colors and an array of locations to place each color within the gradient.
         The system describes the location values as a fractional distance along the polyline between 0.0 (representing the first point) and
         1.0 (representing the last point).
         
         For apps that add a color to the gradient per point in the polyline, `MKPolyline` offers the `location(atPointIndex:)` function to
         compute the location value for use with the gradient polyline.
         */
        var unitDistances = [CGFloat]()
        var colors = [UIColor]()
        var index = 0
        while index < line.pointCount {
            // Figure out the location of a point in the polyline as a fraction of unit distance between 0 and 1.
            unitDistances.append(line.location(atPointIndex: index))
            
            // Pick a color to add to the gradient.
            colors.append(colorPalette[index % colorPalette.count])
            
            index += 1
        }
        
        renderer.setColors(colors, locations: unitDistances)
        renderer.lineWidth = 2
        
        return renderer
    }
}
