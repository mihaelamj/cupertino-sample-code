/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller containing a map view that displays the different types of overlays.
*/

import MapKit
import UIKit

class OverlayViewController: UIViewController {
    
    // The app uses this as the Segue ID.
    enum ExampleOverlay: String, RawRepresentable {
        // Lines and Shapes
        case circle
        case polyline
        case geodesicPolyline
        case closedPolygon
        case crossedPolygon
        case interiorPolygon
        
        // Custom Rendering
        case gradientPolyline
        case multiPolygonRenderer
        case blendModes
        case customRenderer
        
        // Map Tiles
        case tileCoordinates
        case localTiles
        case serverTiles
        case customTileLoading
    }
    
    /// The primary view controller sets this as part of preparing this view controller during the segue.
    var currentExample: ExampleOverlay?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var layerMenuButton: UIBarButtonItem!
    
    /// The standard amount to inset an overlay from the map edge when displaying it.
    let standardPadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    
    /// You can add overlays above roads, or above labels. This is configurable in the sample's menu to see the difference.
    var overlayLevel = MKOverlayLevel.aboveRoads

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.region = LocationData.sanFranciscoDefaultRegion
        
        /// Enables callbacks from the map view to this view controller to configure the overlay renderer objects.
        /// You can also set this in Interface Builder.
        mapView.delegate = self
        
        setupStandardMenu()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayExample()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        /// Redraw the overlays with different colors if the device changes between the light and dark appearance.
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            displayExample()
        }
    }
    
    /// Set up the view controller to show a specific overlay example, based on information from the segue that displays this view controller.
    func displayExample() {
        removeOverlays()
        setupStandardMenu()
        
        switch currentExample {
        case .circle:
            displayCircleExample()
        case .polyline:
            displayPolylineExample()
        case .gradientPolyline:
            displayGradientPolylineExample()
        case .geodesicPolyline:
            displayGeodesicPolylineExample()
        case .closedPolygon:
            displayClosedPolygonExample()
        case .crossedPolygon:
            displayCrossedPolygonExample()
        case .interiorPolygon:
            displayInteriorPolygonExample()
        case .multiPolygonRenderer:
            displayMultiPolygonExample()
        case .blendModes:
            displayBlendModesExample()
        case .customRenderer:
            displayCustomRendererExample()
        case .tileCoordinates:
            displayTileCoordinateExample()
        case .localTiles:
            displayLocalTileExample()
        case .serverTiles:
            displayServerTileExample()
        case .customTileLoading:
            displayCustomLoadingTileExample()
        case nil:
            return
        }
    }
    
    func removeOverlays() {
        let currentOverlays = mapView.overlays
        mapView.removeOverlays(currentOverlays)
    }
    
    private func setupStandardMenu() {
        let levelMenu = UIMenu(title: "Configure Level", options: .displayInline, children: [
            UIAction(title: "Above Labels",
                     image: UIImage(systemName: "character.textbox"),
                     state: overlayLevel == .aboveLabels ? .on : .off) { _ in
                self.overlayLevel = .aboveLabels
                self.displayExample()
            },
            UIAction(title: "Above Roads",
                     image: UIImage(systemName: "road.lanes"),
                     state: overlayLevel == .aboveRoads ? .on : .off) { _ in
                self.overlayLevel = .aboveRoads
                self.displayExample()
            }
        ])
        
        let configMenu = UIMenu(title: "Configure Overlays", options: .displayInline, children: [
            UIAction(title: "Remove All Overlays", image: UIImage(systemName: "minus")) { _ in
                self.removeOverlays()
            },
            UIAction(title: "Restore Overlays", image: UIImage(systemName: "arrow.clockwise")) { _ in
                self.displayExample()
            }
        ])
        
        let menu = UIMenu(children: [levelMenu, configMenu])
        
        layerMenuButton.menu = menu
    }
}

extension OverlayViewController: MKMapViewDelegate {
    
    /**
     When an `MKOverlay` is visible on the map, MapKit calls `mapView(_:rendererFor:)` to configure a renderer object to draw the overlay.
     The renderer objects are customizable, such as for changing the color of a line.
     */
    /// - Tag: create_renderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case let overlay as MKCircle:
            return createCircleRenderer(for: overlay)
        case let overlay as MKGeodesicPolyline:
            return createGeodesicPolylineRenderer(for: overlay)
        case let overlay as MKPolyline where currentExample == .gradientPolyline:
            return createGradientPolylineRenderer(for: overlay)
        case let overlay as MKPolyline:
            return createPolylineRenderer(for: overlay)
        case let overlay as MKPolygon where currentExample == .blendModes:
            return createBlendModesPolygonRenderer(for: overlay)
        case let overlay as MKPolygon:
            return createPolygonRenderer(for: overlay)
        case let overlay as MKMultiPolygon:
            return createMultiPolylineRenderer(for: overlay)
        case let overlay as PeakGroundAccelerationGrid:
            return createCustomRenderer(for: overlay)
        case let overlay as MKTileOverlay:
            return createTileRenderer(for: overlay)
        default:
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
