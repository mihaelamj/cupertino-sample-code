/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model object the workout view uses.
*/

import CoreLocation
import MapKit
import SwiftUI

/// A data model object the workout view uses to track location and gather metrics.
class WorkoutViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        timer.fire()
    }
    
    // MARK: - Properties
    
    @Published var distance = Measurement(value: 0, unit: UnitLength.meters)
    @Published var rate: Double = 0
    @Published var progressTime = 0
    @Published var currentLocation = MKCoordinateRegion()
    
    var locationManager: CLLocationManager? = nil
    var needsAuthorizationAlert: Bool = false
    
    private var locationList: [CLLocation] = []
    
    var timer: Timer {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.progressTime += 1
            self.rate = self.distance.value / Double(self.progressTime)
        }
    }
    
    // MARK: - Methods
    
    func endWorkout() {
        timer.invalidate()
        locationManager?.stopUpdatingLocation()
    }
    
    func verifyLocationServicesEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            let locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.activityType = .fitness
            locationManager.distanceFilter = 5
            self.locationManager = locationManager
            locationAuthorizationRequest()
        }
    }
    
    private func locationAuthorizationRequest() {
        guard let locationManager = locationManager else {
            return
        }
        
        switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.requestWhenInUseAuthorization()
                guard let location = locationManager.location else {
                    return
                }
                let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                currentLocation = MKCoordinateRegion(
                    center: location.coordinate,
                    span: span
                )
                locationManager.startUpdatingLocation()
            case .denied, .restricted:
                needsAuthorizationAlert = true
            @unknown default:
                break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ locationManager: CLLocationManager) {
        locationAuthorizationRequest()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let howRecent = location.timestamp.timeIntervalSinceNow
            guard location.horizontalAccuracy < 20 && abs(howRecent) < 10 else { continue }
            
            if let lastLocation = locationList.last {
                let delta = location.distance(from: lastLocation)
                distance = distance + Measurement(value: delta, unit: UnitLength.meters)
            }
            locationList.append(location)
        }
    }
}
