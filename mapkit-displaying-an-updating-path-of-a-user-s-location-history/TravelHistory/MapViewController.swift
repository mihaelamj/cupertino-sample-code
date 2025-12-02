/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view controller for the app, which displays the user location along with the path they travel on a map view.
*/

import AVFoundation
import CoreLocation
import Foundation
import MapKit
import UIKit

class MapViewController: UIViewController {

    // MARK: Overlay Properties
    
    /// A custom `MKOverlay` that contains the path a user travels.
    var breadcrumbs: BreadcrumbPath!
    
    /// A custom overlay renderer object that draws the data in `crumbs` on the map.
    var breadcrumbPathRenderer: BreadcrumbPathRenderer?
    
    /// A setting that controls whether the `crumbBoundingPolygon` overlay is present on the map.
    var showBreadcrumbBounds = UserDefaults.standard.bool(forKey: SettingsKeys.showCrumbsBoundingArea.rawValue) {
        didSet {
            UserDefaults.standard.set(showBreadcrumbBounds, forKey: SettingsKeys.showCrumbsBoundingArea.rawValue)
            if showBreadcrumbBounds {
                updateBreadcrumbBoundsOverlay()
            } else {
                removeBreadcrumbBoundsOverlay()
            }
        }
    }
    
    /// The bounding rectangle of the breadcrumb overlay. This is only visible when `showBreadcrumbBounds` is `true`.
    var breadcrumbBoundingPolygon: MKPolygon?
    
    // MARK: - Location Mangement Properties
    
    /// The manager interfacing with Core Location.
    let locationManager = CLLocationManager()
    
    /// Location tracking is in an enabled state, and the system is delivering updates to the location manager delegate functions.
    var isMonitoringLocation = false
    
    /// The requested accuracy of the location data.
    var locationAccuracy: CLLocationAccuracy = UserDefaults.standard.double(forKey: SettingsKeys.accuracy.rawValue) {
        didSet {
            locationManager.desiredAccuracy = locationAccuracy
            UserDefaults.standard.set(locationAccuracy, forKey: SettingsKeys.accuracy.rawValue)
        }
    }
    
    /// The type of activity for the location updates.
    var activityType: CLActivityType = CLActivityType(rawValue: UserDefaults.standard.integer(forKey: SettingsKeys.activity.rawValue))! {
        didSet {
            locationManager.activityType = activityType
            UserDefaults.standard.set(activityType.rawValue, forKey: SettingsKeys.activity.rawValue)
        }
    }
    
    /// A setting indicating whether the chime plays on location updates.
    var chimeOnLocationUpdate = UserDefaults.standard.bool(forKey: SettingsKeys.chimeOnLocationUpdate.rawValue) {
        didSet {
            UserDefaults.standard.set(chimeOnLocationUpdate, forKey: SettingsKeys.chimeOnLocationUpdate.rawValue)
        }
    }
    
    // MARK: - Audio Properties
    
    /**
     The audio player for the chime on each location update.
     This makes it easy to tell when location updates occur while the app is in the background.
     */
    var audioPlayer: AVAudioPlayer?
    
    // MARK: - Outlets
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var recordButton: UIBarButtonItem!
    @IBOutlet weak var mapTrackingButton: UIBarButtonItem!
    
    /// This system initalizes this object when it decodes the contents of `Main.storyboard`.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        // Tells the location manager to send updates to this object.
        locationManager.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Allow the user to change the map view's tracking mode by placing this button in the navigation bar.
        mapTrackingButton.customView = MKUserTrackingButton(mapView: mapView)
        
        configureRecordingMenu()
        configureSettingsMenu()
    }
    
    // MARK: - Overlay Methods
    
    // - Tag: renderer_needs_display
    func displayNewBreadcrumbOnMap(_ newLocation: CLLocation) {
        /**
         If the `BreadcrumbPath` model object determines that the current location moves far enough from the previous location,
         use the returned updateRect to redraw just the changed area.
        */
        let result = breadcrumbs.addLocation(newLocation)
        
        /**
         If the `BreadcrumbPath` model object sucessfully adds the location to the path,
         update the rendering of the path to include the new location.
         */
         if result.locationAdded {
            // Compute the currently visible map zoom scale.
            let currentZoomScale = mapView.bounds.size.width / mapView.visibleMapRect.size.width
            
            /**
             Find out the line width at this zoom scale and outset the `pathBounds` by that amount to ensure the full line width draws.
             This covers situations where the new location is right on the edge of the provided `pathBounds`, and only part of the line width
             is within the bounds.
            */
            let lineWidth = MKRoadWidthAtZoomScale(currentZoomScale)
            var areaToRedisplay = breadcrumbs.pathBounds
            areaToRedisplay = areaToRedisplay.insetBy(dx: -lineWidth, dy: -lineWidth)
            
            /**
             Tell the overlay view to update just the changed area, including the area that the line width covers.
             Use `setNeedsDisplay(_:)` to only redraw the changed area of a breadcrumb overlay. For this sample,
             the changed area includes the entire overlay because if the app was recently in the background, the breadcrumb path
             that's visible when the app returns to the foreground might change significantly.

             In general, avoid calling `setNeedsDisplay()` on the overlay renderer without a map rectangle, as that may cause a render
             pass for the entire visible map, only some of which may contain updated data in the overlay.
             
             To avoid an expensive operation, call `setNeedsDisplay(_:)` instead of removing the overlay from the map and then immediately
             adding it back to trigger a render pass when the data is changing often. The rendering of an overlay after adding it to the
             map is not instantaneous, so removing and adding an overlay may cause a visual flicker as the system updates the map view
             without the overlay, and then updates it again with the overlay. This is especially true if the map is displaying more than
             one overlay or updating the overlay data often, such as on each location update.
            */
            breadcrumbPathRenderer?.setNeedsDisplay(areaToRedisplay)
        }
        
        if result.boundingRectChanged {
            /**
             When adding a location, the new location sometimes falls outside of the existing bounding area for the path,
             and the `breadcrumbs` object expands the bounding area to include the new location. When this happens, the app
             needs to recreate the bounds overlay.
             */
            updateBreadcrumbBoundsOverlay()
        }
        
        if breadcrumbs.locations.count == 1 {
            // After determining the user's location, zoom the map to that location, and set the map to follow the user.
            let region = MKCoordinateRegion(center: newLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
        }
    }
    
    private func removeBreadcrumbBoundsOverlay() {
        if let breadcrumbBoundingPolygon {
            mapView.removeOverlay(breadcrumbBoundingPolygon)
        }
    }
    
    /// Recreate and rerender the overlay showing the bounds of the breadcrumb path.
    private func updateBreadcrumbBoundsOverlay() {
       removeBreadcrumbBoundsOverlay()
        
        if showBreadcrumbBounds {
            let pathBounds = breadcrumbs.pathBounds
            let boundingPoints = [
                MKMapPoint(x: pathBounds.minX, y: pathBounds.minY),
                MKMapPoint(x: pathBounds.minX, y: pathBounds.maxY),
                MKMapPoint(x: pathBounds.maxX, y: pathBounds.maxY),
                MKMapPoint(x: pathBounds.maxX, y: pathBounds.minY)
            ]
            breadcrumbBoundingPolygon = MKPolygon(points: boundingPoints, count: boundingPoints.count)
            mapView.addOverlay(breadcrumbBoundingPolygon!, level: .aboveRoads)
        }
    }
}

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? BreadcrumbPath {
            if breadcrumbPathRenderer == nil {
                breadcrumbPathRenderer = BreadcrumbPathRenderer(crumbPath: overlay)
            }
            return breadcrumbPathRenderer!
        } else if overlay is MKPolygon {
            // The rectangle showing the `pathBounds` of the `breadcrumbs` overlay.
            let pathBoundsRenderer = MKPolygonRenderer(overlay: overlay)
            pathBoundsRenderer.fillColor = .systemBlue.withAlphaComponent(0.25)
            return pathBoundsRenderer
        } else {
            fatalError("Unknown overlay \(overlay) added to the map")
        }
    }
}
