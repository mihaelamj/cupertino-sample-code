/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The `SearchViewController` allows the user to search for a location.  The location,
 when selected, will be passed to the `LocationViewController` where it will be
 reported via an `NSUserActivity`.
*/

import UIKit
import MapKit
import CoreLocation
import os.log

class SearchViewController: UITableViewController {

    private static let showLocationSegueID = "showLocation"
    
    @IBOutlet var headerView: UIView!
    
    private var mapItems = [MKMapItem]()
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    private var mapItemToRestore: MKMapItem?
    private var urlToRestore: URL?
    private var phoneNumberToRestore: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableHeaderView = headerView

        // Setup location manager and request authorization to use the current location.
        locationManager.desiredAccuracy = 1000
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestUserLocation()
    }

    private func localSearchWithQuery(_ text: String) {
        // Lookup location using MapKit local search.
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text

        if let location = currentLocation {
            request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        }

        let localSearch = MKLocalSearch(request: request)
        localSearch.start { (response: MKLocalSearch.Response?, error: Error?) in
            DispatchQueue.main.async { [weak self] in
                if let error = error {
                    self?.displayAlert(title: "Unable to find location", message: error.localizedDescription)
                    return
                }

                if let mapItems = response?.mapItems, !mapItems.isEmpty {
                    self?.mapItems = mapItems
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == SearchViewController.showLocationSegueID
            else { return }
        
        guard let navController = segue.destination as? UINavigationController,
            let detailController = navController.topViewController as? LocationViewController else {
                os_log("Unexpected view controller found when preparing for segue", type: .error)
                return
        }
        
        if let indexPath = tableView.indexPathForSelectedRow {
            detailController.mapItem = mapItems[indexPath.row]
        } else {
            detailController.restoreMapItem(mapItemToRestore, url: urlToRestore, phoneNumber: phoneNumberToRestore)
        }
    }
    
    /// - Tag: restore_user_activity_state
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        
        do {
            guard let userInfo = activity.userInfo,
                let url = activity.webpageURL,
                let phoneNumber = userInfo["phoneNumber"] as? String,
                let placemarkData = userInfo["placemark"] as? Data,
                let placemark = try NSKeyedUnarchiver.unarchivedObject(ofClass: MKPlacemark.self, from: placemarkData)
                else { return }
            
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = activity.title
            
            if navigationController?.visibleViewController == self {
                restoreMapItem(mapItem, url: url, phoneNumber: phoneNumber)
            } else if let modalController = navigationController?.visibleViewController as? LocationViewController {
                modalController.restoreMapItem(mapItem, url: url, phoneNumber: phoneNumber)
            }
        } catch {
            os_log("Could not convert user activity placemark data to placemark object", type: .error)
        }
    }
    
    @IBAction func done(_ segue: UIStoryboardSegue) {
        // Unwind segue action.
    }

    private func restoreMapItem(_ mapItem: MKMapItem!, url: URL?, phoneNumber: String?) {
        mapItemToRestore = mapItem
        phoneNumberToRestore = phoneNumber
        urlToRestore = url
        performSegue(withIdentifier: SearchViewController.showLocationSegueID, sender: self)
    }

    private func displayAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .cancel)
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    @IBAction private func requestUserLocation() {
        requestUserLocation(for: locationManager.authorizationStatus)
    }
    
    private func requestUserLocation(for status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
}

/// UITableViewDataSource
extension SearchViewController {

    private static let cellReuseIdentifier: String = "resultCell"
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchViewController.cellReuseIdentifier, for: indexPath)
        let mapItem = mapItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.formattedAddress
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SearchViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        requestUserLocation(for: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
        localSearchWithQuery("Pizza")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown {
            localSearchWithQuery("Pizza")
            return
        }
        
        displayAlert(title: "Failed to obtain current location", message: error.localizedDescription)
        localSearchWithQuery("Pizza")
    }
}
