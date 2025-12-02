/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility class for location functionality.
*/

import Foundation
import CoreLocation

@Observable
class LocationFinder: NSObject, CLLocationManagerDelegate {
    var currentLocation: CLLocation?
    private let currentLocationManager: CLLocationManager = CLLocationManager()

    override init() {
        super.init()
        
        currentLocationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        currentLocationManager.delegate = self
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch currentLocationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            currentLocationManager.requestLocation()
        case .notDetermined:
            currentLocationManager.requestWhenInUseAuthorization()
        default:
            currentLocationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Found a location.")
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print("Received an error while trying to find a location: \(error.localizedDescription).")
        currentLocationManager.stopUpdatingLocation()
    }
}
