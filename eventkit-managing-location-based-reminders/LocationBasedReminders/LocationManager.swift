/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class for managing location services for a person's current location.
*/

import OSLog
import CoreLocation
import MapKit

@MainActor
@Observable class LocationManager: NSObject {
    /// Specifies the location services authorization status for the app.
    var authorizationStatus: CLAuthorizationStatus?
     
    private let locationManager: CLLocationManager
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LocationManager")
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        self.locationManager.delegate = self
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        MainActor.assumeIsolated {
            authorizationStatus = status
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location manager encountered an error: \(error)")
    }
}

/// Extends the coordinate region structure.
extension MKCoordinateRegion {
    /// A region that centers around San Francisco.
    static let sanFrancisco = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.786_996, longitude: -122.440_100),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
}

/// Extends the map item class.
extension MKMapItem {
    /// Returns a formatted address.
    var displayAddress: String {
        addressRepresentations?.fullAddress(includingRegion: true, singleLine: false) ?? "Unknown Address"
    }
}

/// Extends the core location class.
extension CLLocation {
    /// Returns the address of the location.
    func reversedGeocodedLocation() async -> String {
        do {
        
            let request = MKReverseGeocodingRequest(location: self)
            let mapItems = try await request?.mapItems
            
            guard let firstMapItem = mapItems?.first else {
                return "Unknown Address"
            }
            
            return firstMapItem.displayAddress
        } catch {
            return "Unknown Address"
        }
    }
}
