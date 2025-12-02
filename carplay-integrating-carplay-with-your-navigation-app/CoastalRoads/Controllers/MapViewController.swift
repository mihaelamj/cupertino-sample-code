/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`MapViewController` is the root view controller for the car screen. It hosts an instance of `MapScrollView`.
*/

import Foundation
import CarPlay
import MapKit

/**
 `MapViewActionProviding` describes an external object that can trigger UI updates in the map view.
 */
protocol MapViewActionProviding {
    func setZoomInEnabled(_ enabled: Bool)
    func setZoomOutEnabled(_ enabled: Bool)
}

/**
 `MapViewController` is the root view controller for the car screen. It hosts an instance of `MapScrollView`.
 */
class MapViewController: UIViewController {

    var mapView: MapScrollView!
    var mapViewActionProvider: MapViewActionProviding?
    var polylineVisible: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mapImage = UIImage(
                named: "Map",
                in: .main,
                compatibleWith: traitCollection)
        else { fatalError("No map image found") }
        
        // Add the map as the base view for the CarPlay screen.
        // Only add one view and it should cover the entire screen.
        mapView = MapScrollView(frame: view.bounds, image: mapImage)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        mapView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        
        setPolylineVisible(false)
    }
    
    // When the MapViewController is attached to the windows its view will change.
    // This is where the mapView needs to adjust its frame size to the same as the view controller's view.
    // Accordingly the zoom scale needs to be adjusted here.
    override func viewWillLayoutSubviews() {
        let mapViewframe = view.frame
        let imageViewSize = mapView.imageView.bounds
        let scaleWidth = mapViewframe.size.width / imageViewSize.width
        let scaleHeight = mapViewframe.size.height / imageViewSize.height
        let minScale = min(scaleWidth, scaleHeight)
        mapView.minimumZoomScale = minScale
        mapView.maximumZoomScale = 2.0
        mapView.zoomToLocation(.routeOverview)
    }

    /// Coastal Roads navigates with a single predetermined polyline that indicates the route.
    /// When navigation guidance becomes active, the scroll view swaps its background image
    /// in favor of one with a visible polyline.
    func setPolylineVisible(_ visible: Bool) {
        polylineVisible = visible
        let imageName = visible ? "MapLine" : "Map"
        guard let image = UIImage(named: imageName, in: .main, compatibleWith: traitCollection) else { return }
        mapView.imageView.image = image
    }

    // MARK: Panning

    func panInDirection(_ direction: CPMapTemplate.PanDirection) {
        MemoryLogger.shared.appendEvent("Panning to \(direction).")

        var offset = mapView.contentOffset
        // Customize the panning amount to better fit with the sample map.
        switch direction {
        case .down:
            offset.y += mapView.bounds.size.height / 2
        case .up:
            offset.y -= mapView.bounds.size.height / 2
        case .left:
            offset.x -= mapView.bounds.size.width / 2
        case .right:
            offset.x += mapView.bounds.size.width / 2
        default:
            break
        }
        mapView.setContentOffset(offset, animated: true)
    }

    // MARK: Actions

    func zoomIn() {
        mapView.zoomIn()
        updateMapZoom()
    }

    func zoomOut() {
        mapView.zoomOut()
        updateMapZoom()
    }
    
    private func updateMapZoom() {
        mapViewActionProvider?.setZoomInEnabled(mapView.canZoomIn())
        mapViewActionProvider?.setZoomOutEnabled(mapView.canZoomOut())
    }
    
}
