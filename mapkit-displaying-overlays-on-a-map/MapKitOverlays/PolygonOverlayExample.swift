/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example showing how to create different types of polygon overlays and render them on the map.
*/

import Foundation
import MapKit

extension OverlayViewController {
    
    /**
     Creates a polgyon with four verticies. The specific order of locations means the line segments form a closed polygon
     without crossing each other.
     */
    var landmarkPolygon: MKPolygon {
        return MKPolygon(coordinates: LocationData.orderedSanFranciscoLocations, count: LocationData.orderedSanFranciscoLocations.count)
    }

    /// Creates a polgyon with four verticies. The specific order of locations means the line segments forming the polygon cross each other.
    var crossedPolygon: MKPolygon {
        return MKPolygon(coordinates: LocationData.crossedSanFranciscoLocations, count: LocationData.crossedSanFranciscoLocations.count)
    }
    
    /// - Tag: sf_polygon
    /// Creates a rectangle polygon.
    var rectangleOverlay: MKPolygon {
        return MKPolygon(coordinates: LocationData.sanFranciscoRectangle, count: LocationData.sanFranciscoRectangle.count)
    }
    
    func displayClosedPolygonExample() {
        title = "Closed Polygon"
        
        /**
         The system orders overlays by level, drawing them in the order that you add them within each level. First, it draws the initial overlay
         you add, and then draws each additional overlay on top of the previous overlay. Here, the polygon with vertices at major
         San Francisco landmarks is on top of the rectangle overlay.
         */
        mapView.addOverlay(rectangleOverlay, level: overlayLevel)
        mapView.addOverlay(landmarkPolygon, level: overlayLevel)
        
        /// Focus the map on the overlay, adding space around the edges to frame it nicely within the view controller's view.
        mapView.setVisibleMapRect(rectangleOverlay.boundingMapRect, edgePadding: standardPadding, animated: false)
    }
    
    func displayCrossedPolygonExample() {
        title = "Crossed Polygon"
        
        /**
         The system forms a polygon by drawing a line between the coordinates. When a line crosses another line, only the
         interior areas that the crossed lines create are part of the final polygon, according to the even-odd fill rule.
         */
        mapView.addOverlay(crossedPolygon, level: overlayLevel)
        
        /// To see how the system defines the interior area for `crossedPolygon`, draw a polyline using the same coordinates.
        mapView.addOverlay(crossedPolyline, level: overlayLevel)
        
        /// Focus the map on the overlay, adding space around the edges to frame it nicely within the view controller's view.
        mapView.setVisibleMapRect(crossedPolygon.boundingMapRect, edgePadding: standardPadding, animated: false)
    }
    
    func displayInteriorPolygonExample() {
        title = "Interior Polygon"
        
        /// You can nest polygons inside each other to create a cutout in an outer polygon.
        let interiorCross = MKPolygon(coordinates: LocationData.crossedSanFranciscoLocations, count: LocationData.crossedSanFranciscoLocations.count)
        let polygon = MKPolygon(coordinates: LocationData.sanFranciscoRectangle,
                                count: LocationData.sanFranciscoRectangle.count,
                                interiorPolygons: [interiorCross])
        mapView.addOverlay(polygon, level: overlayLevel)
        
        /// Focus the map on the overlay, adding space around the edges to frame it nicely within the view controller's view.
        mapView.setVisibleMapRect(polygon.boundingMapRect, edgePadding: standardPadding, animated: false)
    }
   
    func createPolygonRenderer(for polygon: MKPolygon) -> MKPolygonRenderer {
        let renderer = MKPolygonRenderer(polygon: polygon)
        renderer.alpha = 0.5
        renderer.lineWidth = 2
        
        var fillColor = UIColor.systemMint
        
        if polygon.coordinates == LocationData.sanFranciscoRectangle {
            fillColor = .systemRed
            
            // Create a dotted line pattern around the edge.
            renderer.lineDashPattern = [1 as NSNumber, 5 as NSNumber]
        } else if polygon.coordinates == LocationData.orderedSanFranciscoLocations {
            fillColor = .systemPurple
        } else if polygon.coordinates == LocationData.crossedSanFranciscoLocations {
            fillColor = .systemOrange
        }
        
        renderer.fillColor = fillColor
        
        // Use a saturated version of the fill color for the border color of the polygon.
        var hue: CGFloat = 0.0
        var saturation: CGFloat  = 0.0
        var brightness: CGFloat  = 0.0
        var alpha: CGFloat = 0.0
        fillColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        renderer.strokeColor = UIColor(hue: hue, saturation: 1.0, brightness: brightness, alpha: alpha)
        
        return renderer
    }
}
