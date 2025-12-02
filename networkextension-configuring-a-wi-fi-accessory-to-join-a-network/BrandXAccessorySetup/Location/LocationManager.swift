/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The LocationManager class to receive location updates for the app.
*/

import Foundation
import CoreLocation

class LocationManager: NSObject {
    
    // MARK: - Public constants
    
    public static let shared = LocationManager()
    
    // MARK: - Private variables
    
    private var locationManger: CLLocationManager?
    
    // MARK: - Public CoreLocation Methods
    
    func startLocationManager() {
        
        if let locManager = locationManger {
            // If you’re starting locationManager for the second time, such as in ConfirmNetwork, don't set accuracy and delegate again.
            locManager.requestWhenInUseAuthorization()
            locManager.startUpdatingLocation()
            return
        }
        
        let manager = CLLocationManager()
        locationManger = manager
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func stopLocationManager() {
        locationManger?.stopUpdatingLocation()
    }
    
}

// MARK: - CLLocationManagerDelegate Methods

extension LocationManager: CLLocationManagerDelegate {
    
    // MARK: - CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            print("<LocationManager> lastLocation:\(lastLocation.coordinate.latitude), \(lastLocation.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Detect the CLAuthorizationStatus and enable the capture of the associated SSID.
        if status == CLAuthorizationStatus.authorizedAlways ||
            status == CLAuthorizationStatus.authorizedWhenInUse {
            print("<LocationManager> authorizedAlways || authorizedWhenInUse")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            print("<LocationManager> Error Denied: \(error.localizedDescription)")
            manager.stopUpdatingLocation()
        }
    }
}

