/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`TourViewController` displays the map view and animates the map to each `ItineraryItem` stop on the tour.
*/

import CoreLocation
@preconcurrency import MapKit
import UIKit

class TourViewController: UIViewController {
    
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleEffectView: UIVisualEffectView!
    @IBOutlet private weak var lookAroundContainerView: UIView!
    @IBOutlet private weak var nextButton: UIButton!
    
    /// The Look Around view controller contained in `lookAroundContainerView`.
    private var lookAroundViewController: MKLookAroundViewController!
    
    /// The tour's itinerary.
    var itinerary: Itinerary!
    
    /// Results of loading objects of type `MKRoute`.
    private var mapRouteResults = MapDataResults<MapRouteID, MKRoute?>()
    
    /// The index in the `itinerary.stops` array of the current stop in the tour.
    private var currentStopIndex: Int!
    
    /// Initially configure the user interface when the view is loaded.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Find the `MKLookAroundViewController` that is created as a child of this view controller in Interface Builder.
        lookAroundViewController = children.compactMap { $0 as? MKLookAroundViewController }.first

        // Limit the map to the San Francisco region by centering the map on the region, and setting a
        // boundary restriction and a zoom range to keep the map to this region.
        let centerOfSanFrancisco = CLLocationCoordinate2D(latitude: 37.754_48, longitude: -122.442_49)
        mapView.region = MKCoordinateRegion(center: centerOfSanFrancisco, latitudinalMeters: 20_000, longitudinalMeters: 20_000)
        
        let boundaryRegion = MKCoordinateRegion(center: centerOfSanFrancisco, latitudinalMeters: 40_000, longitudinalMeters: 40_000)
        mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: boundaryRegion)
        
        let zoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 100, maxCenterCoordinateDistance: 40_000)
        mapView.cameraZoomRange = zoomRange
        
        // Enable the realistic detail map to get the highest amount of map detail. This can also be configured in Interface Builder.
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic)
        
        // Hide UI elements initially.
        nextButton.alpha = 0
        titleLabel.text = nil
        titleEffectView.alpha = 0
        lookAroundContainerView.alpha = 0
    }
    
    /// Set the starting point of the tour when the view is first displayed.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Start the tour, if the view has just been loaded.
        if currentStopIndex == nil {
            
            // Set the starting stop of the tour.
            currentStopIndex = 0
            
            // If there are no stops on the tour, simply allow the tour to end.
            guard currentStopIndex < itinerary.stops.count else {
                configureArrival(at: currentStopIndex)
                return
            }
            
            // Otherwise, animate from the San Francisco region overview to the first stop.
            animateArrival(at: currentStopIndex, afterDelay: 1)
        }
    }
    
    /// Advances the tour to the next stop, or ends the tour if there are no more stops.
    @IBAction func goToNextStop(_ sender: Any) {
        guard nextButton.alpha == 1 else { return }
        
        // Check if the tour is over.
        guard currentStopIndex + 1 < itinerary.stops.count else {
            dismiss(animated: true)
            return
        }
        
        // Disable the user interface until the next stop is reached.
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [self] in
            nextButton.alpha = 0
            lookAroundContainerView.alpha = 0
        }
        
        // Advance to the next stop.
        animateTravel(from: currentStopIndex)
        currentStopIndex += 1
    }
    
    /// After a configurable delay, animates the camera to the preferred vantage point for the map item you're arriving at, before setting up the
    /// user interface for Look Around at this location and preparing for the next stop.
    private func animateArrival(at stopIndex: Int, afterDelay delay: Double = 0) {
        guard stopIndex < itinerary.stops.count else { return }
        let stop = itinerary.stops[stopIndex]
        
        // Asynchronously wait for the duration of the delay, and then start the animation.
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            UIView.animate(withDuration: 3, delay: 0, options: .curveEaseInOut) { [self] in
                // When a `MKMapItem` represents a landmark, `MKMapCamera` uses a curated camera framing
                // that is best for the specific landmark when created through `MKMapCamera(lookingAt:forViewSize:allowPitch:)`.
                mapView.camera = MKMapCamera(lookingAt: stop.mapItem, forViewSize: mapView.bounds.size, allowPitch: true)
            } completion: { [self] _ in
                configureArrival(at: stopIndex)
            }
        }
    }
    
    /// Sets up the user interface for Look Around at this stop and prepares for the next stop.
    private func configureArrival(at stopIndex: Int) {
        
        // If there is no next stop in the tour, adjust the user interface for ending the tour.
        if stopIndex + 1 >= itinerary.stops.count {
            nextButton.setTitle("Close", for: .normal)
            nextButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        }
        
        // If there is no current stop, allow the tour to end.
        guard stopIndex < itinerary.stops.count else {
            lookAroundContainerView.alpha = 0
            nextButton.alpha = 1
            return
        }
        
        let stop = itinerary.stops[stopIndex]
        
        // Check if there's another stop remaining in the itinerary.
        if stopIndex + 1 < itinerary.stops.count {
            let nextStop = itinerary.stops[stopIndex + 1]
            
            // Start asynchronously loading the route to the next stop, so the route is
            // available by the time the user navigates to the next stop.
            prepareMapRoute(from: stop, to: nextStop)
            
            // Adjust the user interface for travel to the next stop.
            nextButton.setTitle(String(localized: "Next"), for: .normal)
            nextButton.setImage(UIImage(systemName: "arrow.forward.circle.fill"), for: .normal)
        }
        
        // Show the title of the current stop.
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [self] in
            titleLabel.text = stop.title
            titleEffectView.alpha = 1
            
            // Allow the tour to proceed to the next stop.
            nextButton.alpha = 1
        }
        
        // Asynchronously configure the Look Around scene for the current stop.
        Task {
            
            // Get the Look Around scene for this stop.
            let lookAroundScene: MKLookAroundScene?
            do {
                lookAroundScene = try await itinerary.lookAroundScene(for: stop.mapItemID)
            } catch {
                lookAroundScene = nil
            }
            
            // Show the Look Around scene user interface if the scene is available.
            var lookAroundVisible = false
            if let lookAroundScene = lookAroundScene {
                lookAroundViewController.scene = lookAroundScene
                lookAroundVisible = true
            }
        
            // Display the Look Around scene if it is available.
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [self] in
                lookAroundContainerView.alpha = lookAroundVisible ? 1 : 0
            }
        }
    }
    
    /// Animates the camera along the route to the next stop.
    private func animateTravel(from stopIndex: Int) {
        let currentStop = itinerary.stops[stopIndex]
        let nextStop = itinerary.stops[stopIndex + 1]
        
        // Remove the previous route overlay.
        mapView.removeOverlays(mapView.overlays)
        
        // Hide the stop description while animating.
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [self] in
            titleLabel.text = nil
            titleEffectView.alpha = 0
        }
        
        // Asynchronously finish loading the route, if necessary, and start the travel animation when loading is done.
        Task {
            let mapRoute: MKRoute?
            do {
                mapRoute = try await preparedMapRoute(from: currentStop, to: nextStop)
            } catch {
                mapRoute = nil
            }
            
            /*
             Display the driving directions, and animate the map so the starting point, ending point,
             and the overall route are visible.
             
             When the map is pitched, route polylines created through `MKDirections.Request` follow the elevation of the
             terrain, such as hills, overpasses, and bridges. Further, these polylines blend with the surrounding landscape,
             so they are visible through buildings, trees, and in tunnels. Take note of these examples:
             
             1. When navigating from the Golden Gate Bridge to the Palace of Fine Arts, the route goes through multiple
             tunnels. If you zoom in on these sections of the route, the section of the polyline in the tunnels is blended with
             the surrounding terrain.
             
             2. When zooming in to Coit Tower, the elevation of Telegraph Hill becomes visible, and the route polyline follows
             the road elevation as it ascends Telegraph Hill to Coit Tower. The route polyline to Sutro Tower also demonstrates this.
             */
            if let mapRoute = mapRoute {
                
                mapView.addOverlay(mapRoute.polyline)

                /*
                 Animate the starting point for navigation into view. The origin might be out of view if the user
                 moved the map away from the landmark, or if the starting point is significantly separated from the
                 landmark. For example, navigating away from Alcatraz Island starts at the boat dock in San Francisco,
                 so adjust the visible map rectangle to include the navigation starting point as well as the landmark.
                 */
                UIView.animate(withDuration: 3, delay: 0, options: .curveEaseInOut) { [self] in

                    // Bring the start and end points away from the edge of the map.
                    let insets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
                    let startDestination = MKMapRect(origin: MKMapPoint(currentStop.coordinate), size: MKMapSize(width: 1, height: 1))
                    let navigationVisibleRect = mapRoute.polyline.boundingMapRect.union(startDestination)

                    mapView.setVisibleMapRect(navigationVisibleRect, edgePadding: insets, animated: true)
                } completion: { _ in

                    UIView.animate(withDuration: 3, delay: 0, options: .curveEaseInOut) { [self] in
                        
                        /*
                         This animation zooms in to the last point on the navigation route. For most cases, this is the
                         same location as the destination landmark on the tour. For Alcatraz Island, the last navigation
                         point is the ferry departure point. Subsequent animations animate to Alcatraz Island itself.
                         */
                        let pointCount = mapRoute.polyline.pointCount
                        let lastPoint = mapRoute.polyline.points()[pointCount - 1]
                        
                        // Because this animation comes after the map animates out to be unpitched, a heading of 0 results in a smooth
                        // transition (without undue rotation) as the map zooms in on the destination while regaining a pitch.
                        mapView.camera = MKMapCamera(lookingAtCenter: lastPoint.coordinate, fromDistance: 1500, pitch: 60, heading: 0)
                    } completion: { _ in
                        self.animateArrival(at: stopIndex + 1)
                    }
                }
            }
            
            // Otherwise, animate directly to the next stop location.
            else {
                animateArrival(at: stopIndex + 1)
            }
        }
    }
    
    /// Gets a map route between a starting and ending location, assuming that loading was previously started using `prepareMapRoute(from:to:)`.
    /// - parameter startMapItemID: The item ID of the starting map item.
    /// - parameter endMapItemID: The item ID of the ending map item.
    /// - returns: The requested route, or ` nil` if no route can be found.
    func preparedMapRoute(from startingStop: ItineraryStop, to endingStop: ItineraryStop) async throws -> MKRoute? {
        let mapRouteID = MapRouteID(startItemID: startingStop.mapItemID, endItemID: endingStop.mapItemID)
        return try await mapRouteResults.preloadedResult(for: mapRouteID).get()
    }
    
    /// Preloads a map route between a starting and ending location, so that it is available later through `preparedMapRoute(from:to:) async`.
    /// - parameter startMapItemID: The item ID of the starting map item.
    /// - parameter endMapItemID: The item ID of the ending map item.
    func prepareMapRoute(from startingStop: ItineraryStop, to endingStop: ItineraryStop) {
        let mapRouteID = MapRouteID(startItemID: startingStop.mapItemID, endItemID: endingStop.mapItemID)
        
        // If loading has already been completed (a result already exists),
        // or is in progress (a `Task` already exists), there's nothing to do.
        guard mapRouteResults.availableResult(for: mapRouteID) == nil else { return }
        
        // If not, then start loading in a separate `Task`.
        // Note that the `Task` doesn't need to do anything with the result,
        // because it's not needed until `preparedMapRoute(from:to:)` is called.
        Task {
            _ = await mapRouteResults.result(for: mapRouteID) {
                
                // Find the map route, if possible.
                let directionsRequest = MKDirections.Request()
                directionsRequest.source = startingStop.mapItem
                directionsRequest.destination = endingStop.mapItem
                directionsRequest.transportType = .automobile
                
                let directionsService = MKDirections(request: directionsRequest)
                let response = try await directionsService.calculate()
                let route = response.routes.first
                
                return route
            }
        }
    }
}

/// Adds `MKMapViewDelegate` conformance to `TourViewController`.
extension TourViewController: MKMapViewDelegate {
    
    /// Configures the appearance of the map route overlay.
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let overlay = overlay as? MKPolyline else {
            fatalError("Unexpected overlay \(overlay) added to the map view")
        }
        
        let renderer = MKPolylineRenderer(polyline: overlay)
        renderer.strokeColor = .tintColor
        renderer.lineWidth = 6
        
        return renderer
    }
    
}
