/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that manages a map and the user's activity within it, creating and receiving NSUserActivity objects for Handoff.
*/

import Cocoa
import MapKit

class MapViewController: NSViewController {

    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 2000.0
        return locationManager
    }()
    
    @IBOutlet private weak var mapView: MKMapView!
    private var initialMapRegionState: InitialMapRegionState = .notSet
    private let maxSearchLatitude: CLLocationDegrees = 10.0
    private var editingStore: AppleStore?

    private lazy var storeDirectory: AppleStoreDirectory = {
        let directory = AppleStoreDirectory()
        directory.onStoresFound = { newStores in
            DispatchQueue.main.async {
                for newStore in newStores {
                    self.mapView.addAnnotation(AppleStoreAnnotation(store: newStore))
                }
            }
        }
        return directory
    }()
    private lazy var mapViewingActivity: NSUserActivity = {
        let activity = NSUserActivity.initForRegionViewing()
        activity.delegate = self
        return activity
    }()
    private lazy var storeEditingActivity: NSUserActivity = {
        let activity = NSUserActivity.initForStoreEditing()
        activity.delegate = self
        return activity
    }()
    
    // MARK: - NSViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if case .notSet = initialMapRegionState {
            // Wait briefly for Handoff to possibly set initialMapRegionState, then default to current location.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                if case .notSet = self.initialMapRegionState {
                    self.locationManager.requestLocation()
                }
            }
        }
    }

    private func dismissDetailPopover() {
        guard let vcs = self.presentedViewControllers else { return }
        for storeVC in vcs.filter({ $0 is StoreDetailViewController }) {
            self.dismiss(storeVC)
        }
    }
    
    private func detailPopoverIsPresented() -> Bool {
        guard let vcs = self.presentedViewControllers else { return false }
        return vcs.filter({ $0 is StoreDetailViewController }).isEmpty ? false : true
    }
    
    // MARK: - Handoff support
    override func updateUserActivityState(_ activity: NSUserActivity) {
        activity.updateViewingRegion(mapView.region)
        if activity.activityType == NSUserActivity.storeEditingActivityType,
            let editingStore = editingStore {
            activity.updateEditing(store: editingStore)
        }
    }
    
    override func restoreUserActivityState(_ userActivity: NSUserActivity) {
        super.restoreUserActivityState(userActivity)
        
        switch userActivity.activityType {
        // If this is a map viewing activity, restore the map region.
        case NSUserActivity.viewingActivityType:
            guard let viewingRegion = userActivity.viewingRegion() else {
                return
            }
            if case .notSet = self.initialMapRegionState {
                self.initialMapRegionState = .setFromHandoff
            }
            DispatchQueue.main.async {
                self.storeDirectory.findAppleStores(in: viewingRegion)
                self.mapView.setRegion(viewingRegion, animated: true)
            }
            
        // If this is a map editing activity, set the map to the right location.
        // Popover can be shown once the map adds the store's annotation.
        case NSUserActivity.storeEditingActivityType:
            guard let storeRegion = userActivity.viewingRegion(),
            let storeURL = userActivity.editingStoreURL() else {
                    return
            }

            DispatchQueue.main.async {
                self.storeDirectory.findAppleStores(in: storeRegion)
                self.mapView.setRegion(storeRegion, animated: false)
                self.initialMapRegionState = .loadingHandoffForStore(url: storeURL, coordinate: storeRegion.center)
            }
            
        default:
            break
        }
    }
    
    private func showPopoverForEditingHandoff(for store: AppleStore, relativeTo annotationView: MKAnnotationView) {
        guard let detailVC = storyboard?.instantiateController(withIdentifier: "StoreDetailScene")
            as? StoreDetailViewController else { return }
        
        detailVC.store = store
        detailVC.storeDirectory = storeDirectory
        // Add a short delay to wait out map smoothing animation.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.present(detailVC,
                         asPopoverRelativeTo: annotationView.bounds,
                         of: annotationView,
                         preferredEdge: .maxX,
                         behavior: .semitransient)
        }
    }
    
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        // Update activity with viewed region, unless user has already gone into editing mode.
        if !detailPopoverIsPresented() {
            userActivity = mapViewingActivity
            mapViewingActivity.needsSave = true
            mapViewingActivity.becomeCurrent()
        }
        
        if mapView.region.span.latitudeDelta < maxSearchLatitude {
            storeDirectory.findAppleStores(in: mapView.region)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)

        guard let storeAnnotation = view.annotation as? AppleStoreAnnotation,
            let detailVC = storyboard?.instantiateController(withIdentifier: "StoreDetailScene")
                as? StoreDetailViewController else { return }
        
        editingStore = storeAnnotation.store
        // Show the popover.
        dismissDetailPopover()
        detailVC.store = storeAnnotation.store
        detailVC.storeDirectory = storeDirectory
        present(detailVC,
                asPopoverRelativeTo: view.bounds,
                of: view,
                preferredEdge: .minY,
                behavior: .semitransient)
        
        // Update Handoff.
        userActivity = storeEditingActivity
        storeEditingActivity.needsSave = true
        storeEditingActivity.becomeCurrent()
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        // If the state indicates we are waiting on a store-editing activity,
        // see if any of the new views represent that store.
        if case let .loadingHandoffForStore(storeURL, _) = self.initialMapRegionState,
            let annotationView = views.first(where: {
                ($0.annotation as? AppleStoreAnnotation)?.store.url.absoluteString == storeURL.absoluteString }),
            let storeAnnotation = annotationView.annotation as? AppleStoreAnnotation {
            self.showPopoverForEditingHandoff(for: storeAnnotation.store, relativeTo: annotationView)
            self.initialMapRegionState = .setFromHandoff
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("got \(locations.count) locations")
        let region = MKCoordinateRegion(center: locations[0].coordinate,
                                        latitudinalMeters: CLLocationDistance(50_000),
                                        longitudinalMeters: CLLocationDistance(50_000))
        mapView.setRegion(region, animated: true)
        initialMapRegionState = .setFromCurrentLocation
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // If location manager fails to get location, we can't automatically set map region, so stop trying.
        manager.stopUpdatingLocation()
    }
}

extension MapViewController: NSPopoverDelegate {
    
    func popoverDidClose(_ notification: Notification) {
        // If we dismiss the popover, the activity should no longer be editing.
        editingStore = nil
        userActivity = mapViewingActivity
        mapViewingActivity.needsSave = true
        mapViewingActivity.becomeCurrent()
    }
}

// MARK: - NSUserActivityDelegate
extension MapViewController: NSUserActivityDelegate {
    
    func userActivityWasContinued(_ userActivity: NSUserActivity) {
        // Dismiss the popover, if it is showing.
        DispatchQueue.main.async {
            self.dismissDetailPopover()
        }
    }
}
