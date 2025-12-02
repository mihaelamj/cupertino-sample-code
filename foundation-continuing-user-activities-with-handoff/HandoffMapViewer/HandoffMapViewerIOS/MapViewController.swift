/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that manages a map and the user's activity within it, creating and receiving NSUserActivity objects for Handoff.
*/

import UIKit
import MapKit

class MapViewController: UIViewController {

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

    // MARK: - UIViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        storeEditingActivity.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Wait briefly for Handoff to possibly set initialMapRegionState, then default to current location.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            if case .notSet = self.initialMapRegionState {
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
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
        mapView.delegate = self
        
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

        // If this is a map editing activity, restore the editing UI.
        case NSUserActivity.storeEditingActivityType:
            guard let storeRegion = userActivity.viewingRegion(),
                let storeURL = userActivity.editingStoreURL() else {
                    return
            }

            self.initialMapRegionState = .loadingHandoffForStore(url: storeURL, coordinate: storeRegion.center)
            DispatchQueue.main.async {
                self.storeDirectory.findAppleStores(in: storeRegion)
                self.mapView.setRegion(storeRegion, animated: false)
            }
            
        default:
            break
        }
    }

    private func showPopoverForEditingHandoff(for store: AppleStore, relativeTo annotationView: MKAnnotationView) {
        guard let detailVC = storyboard?.instantiateViewController(withIdentifier: "StoreDetailScene")
            as? StoreDetailViewController else { return }
        
        detailVC.store = store
        detailVC.storeDirectory = storeDirectory
        presentedViewController?.dismiss(animated: false)
        // Add a short delay to wait out map smoothing animation.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            guard let storeAnnotation = annotationView.annotation as? AppleStoreAnnotation,
                let detailVC = self.storyboard?.instantiateViewController(withIdentifier: "StoreDetailScene")
                    as? StoreDetailViewController else { return }
            detailVC.modalPresentationStyle = .popover
            detailVC.preferredContentSize = CGSize(width: 375, height: 200)
            detailVC.popoverPresentationController?.delegate = self
            detailVC.popoverPresentationController?.sourceView = annotationView
            detailVC.store = storeAnnotation.store
            self.present(detailVC, animated: true)
        }
    }
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        // Update activity with viewed region, unless user has already gone into editing mode.
        if presentedViewController == nil {
            userActivity = mapViewingActivity
            mapViewingActivity.needsSave = true
            mapViewingActivity.becomeCurrent()
        }

        if mapView.region.span.latitudeDelta < maxSearchLatitude {
            storeDirectory.findAppleStores(in: mapView.region)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("selected annotation view for \(String(describing: view.annotation?.title))")
        mapView.deselectAnnotation(view.annotation, animated: false)

        // Show the popover.
        guard let storeAnnotation = view.annotation as? AppleStoreAnnotation,
            let detailVC = storyboard?.instantiateViewController(withIdentifier: "StoreDetailScene")
                as? StoreDetailViewController else { return }

        editingStore = storeAnnotation.store
        detailVC.modalPresentationStyle = .popover
        detailVC.preferredContentSize = CGSize(width: 375, height: 200)
        detailVC.popoverPresentationController?.delegate = self
        detailVC.popoverPresentationController?.sourceView = view
        detailVC.store = storeAnnotation.store
        detailVC.storeDirectory = storeDirectory
        present(detailVC, animated: true)
        
        // Update handoff.
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("got authorized")
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("got \(locations.count) locations")
        let region = MKCoordinateRegion(center: locations[0].coordinate,
                                        latitudinalMeters: CLLocationDistance(50_000),
                                        longitudinalMeters: CLLocationDistance(50_000))
        mapView.setRegion(region, animated: true)
        initialMapRegionState = .setFromCurrentLocation
        manager.stopUpdatingLocation()
    }
    
}

// MARK: - UIPopoverPresentationControllerDelegate
extension MapViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // On iPhone, show the popover rather than the modal sheet.
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        // If user dismisses the popover, their activity should no longer be editing.
        editingStore = nil
        userActivity = mapViewingActivity
        mapViewingActivity.needsSave = true
        mapViewingActivity.becomeCurrent()
    }
    
}

// MARK: - NSUserActivityDelegate
extension MapViewController: NSUserActivityDelegate {

    func userActivityWasContinued(_ userActivity: NSUserActivity) {
        DispatchQueue.main.async {[weak self] in
            if let detailVC = self?.presentedViewController as? StoreDetailViewController,
               userActivity.activityType == NSUserActivity.storeEditingActivityType {
                detailVC.dismiss(animated: true)
            }
        }
    }
}
