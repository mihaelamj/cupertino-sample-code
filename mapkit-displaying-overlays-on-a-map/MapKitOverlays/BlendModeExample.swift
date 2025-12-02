/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example showing how to create visual effects by applying blend modes to the overlay renderer.
*/

import Foundation
import MapKit

extension OverlayViewController {
 
    func displayBlendModesExample() {
        title = "Blend Modes"
        
        /// Display the standard map instead of the muted map that other examples use.
        mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .default)
        
        /// Set up the overlays to create the highlight effect.
        createAndDisplayBlendModeMapOverlays()
        
        /// To help highlight the park, turn off all points of interest using an `excludingAll` filter.
        mapView.pointOfInterestFilter = .excludingAll
    }
    
    /**
     To create a visual effect, stack multiple map overlays in a specific order, and apply a blend mode to each overlay to create the
     desired visual effect.
     
     This sample creates a bold visual effect on a park to highlight the location of a concert by making the park stand out from the rest of the map.
     This effect is created with two overlays. The first overlay masks the entire map, except for a polygon containing the highlighted park.
     Applying a screen blend mode to this overlay deemphasizes most of the map, except for the park. The second overlay is a polygon for the park,
     which matches the area that the first overlay doesn't mask.
     
     The desaturation blend mode on the first overlay helps highlight the park by toning down the colors on other areas of the map.
     Applying a color burn blend mode to the second overlay, which only covers the park, makes the park appear more vibrant,
     helping it stand out further.
     */
    /// - Tag: blend_mode_overlay
    private func createAndDisplayBlendModeMapOverlays(includeDesaturationMask: Bool = true, includeColorBurn: Bool = true) {
        removeOverlays()
        mapView.removeAnnotations(mapView.annotations)
        
        /// Turn an array of points into a polygon. You can also load the polygon from a GeoJSON file by using `MKGeoJSONDecoder`.
        let parkPolygon = MKPolygon(coordinates: LocationData.plazaDeCesarChavezParkOutline,
                                         count: LocationData.plazaDeCesarChavezParkOutline.count)
        
        /// Create an overlay polygon that covers the entire world, except for a cutout of the highlighted park.
        let worldPoints = [MKMapRect.world.origin,
                           MKMapPoint(x: MKMapRect.world.origin.x, y: MKMapRect.world.origin.y + MKMapRect.world.size.height),
                           MKMapPoint(x: MKMapRect.world.origin.x + MKMapRect.world.size.width, y: MKMapRect.world.origin.y),
                           MKMapPoint(x: MKMapRect.world.origin.x + MKMapRect.world.size.width,
                                      y: MKMapRect.world.origin.y + MKMapRect.world.size.height)]
        let desaturatedBase = MKPolygon(points: worldPoints, count: worldPoints.count, interiorPolygons: [parkPolygon])
        
        if includeDesaturationMask {
            mapView.addOverlay(desaturatedBase, level: overlayLevel)
        }
        
        if includeColorBurn {
            mapView.addOverlay(parkPolygon, level: overlayLevel)
        }
        
        /**
         Types that derive from `MKOverlay`, such as `MKPolygon`, also conform to `MKAnnotation`, enabling you to add them to the map as an overlay,
         as well as place an annotation on the overlay to label it.
         */
        parkPolygon.title = "Concert Location"
        mapView.addAnnotation(parkPolygon)
        
        /// Focus the map on the overlay, adding space around the edges to frame it nicely within the view controller's `view`.
        mapView.setVisibleMapRect(parkPolygon.boundingMapRect, edgePadding: standardPadding, animated: false)
        
        /// Create a menu for controlling the different overlays to see how the blend modes combine to create the highlight effect.
        layerMenuButton.menu = UIMenu(title: "Configure Blend Overlays", children: [
            UIAction(title: "Desaturation Overlay",
                     state: includeDesaturationMask ? .on : .off) { _ in
                         // Reverse the current state.
                         var value = includeDesaturationMask
                         value.toggle()
                         self.createAndDisplayBlendModeMapOverlays(includeDesaturationMask: value, includeColorBurn: includeColorBurn)
            },
            UIAction(title: "Color Burn Overlay",
                     state: includeColorBurn ? .on : .off) { _ in
                         // Reverse the current state.
                         var value = includeColorBurn
                         value.toggle()
                         self.createAndDisplayBlendModeMapOverlays(includeDesaturationMask: includeDesaturationMask, includeColorBurn: value)
            }
        ])
    }
    
    /// - Tag: blend_mode_renderer
    func createBlendModesPolygonRenderer(for overlay: MKPolygon) -> MKPolygonRenderer {
        let renderer = MKPolygonRenderer(polygon: overlay)
        
        if overlay.interiorPolygons == nil {
            /// An overlay without `interiorPolygons` is the overlay highlighting the park.
            renderer.fillColor = traitCollection.userInterfaceStyle == .light ? .darkGray : .white
            renderer.blendMode = .colorBurn
        } else {
            /// An overlay with `interiorPolygons` is the background overlay to desaturate.
            renderer.fillColor = .gray
            renderer.blendMode = .screen
        }
        return renderer
    }
}
