/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides auxiliary functions for handling UI configuration for menus and toolbar buttons.
*/

import CoreLocation
import MapKit
import UIKit

/// The name of the settings for storing with `UserDefaults`.
enum SettingsKeys: String {
    case accuracy
    case chimeOnLocationUpdate
    case showCrumbsBoundingArea
    case activity
}

extension MapViewController {
    
    /// A menu for displaying the map's settings.
    private var mapSettingsMenu: UIMenu {
        let menu = UIMenu(title: "Map", options: .displayInline, children: [
            UIAction(title: "Display Breadcrumb Bounds",
                     state: showBreadcrumbBounds ? .on : .off,
                     handler: { _ in
                         self.showBreadcrumbBounds.toggle()
                         self.configureSettingsMenu()
                     })
        ])
        
        return menu
    }
    
    /// A menu for displaying the settings for audio feedback.
    private var audioSettingsMenu: UIMenu {
        let menu = UIMenu(title: "Audio", options: .displayInline, children: [
            UIAction(title: "Play Sound on Location Updates",
                     state: chimeOnLocationUpdate ? .on : .off,
                     handler: { _ in
                         self.chimeOnLocationUpdate.toggle()
                         self.configureSettingsMenu()
                     })
        ])
        
        return menu
    }
    
    /// A menu for displaying the settings for location accuracy.
    private var locationAccuracyMenu: UIMenu {
        func updateLocationAccuracy(_ newAccuracy: CLLocationAccuracy) {
            self.locationAccuracy = newAccuracy
            self.configureSettingsMenu()
        }
        
        let accuracyOptions = UIMenu(title: "Location Accuracy", options: .displayInline, children: [
            UIAction(title: "Best Accuracy for Navigation",
                     state: locationAccuracy == kCLLocationAccuracyBestForNavigation ? .on : .off,
                     handler: { _ in
                         updateLocationAccuracy(kCLLocationAccuracyBestForNavigation)
                     }),
            UIAction(title: "Best Accuracy",
                     state: locationAccuracy == kCLLocationAccuracyBest ? .on : .off,
                     handler: { _ in
                         updateLocationAccuracy(kCLLocationAccuracyBest)
                     }),
            UIAction(title: "Within 10 Meters",
                     state: locationAccuracy == kCLLocationAccuracyNearestTenMeters ? .on : .off,
                     handler: { _ in
                         updateLocationAccuracy(kCLLocationAccuracyNearestTenMeters)
                     }),
            UIAction(title: "Within 100 Meters",
                     state: locationAccuracy == kCLLocationAccuracyHundredMeters ? .on : .off,
                     handler: { _ in
                         updateLocationAccuracy(kCLLocationAccuracyHundredMeters)
                     }),
            UIAction(title: "Within 1 Kilometer",
                     state: locationAccuracy == kCLLocationAccuracyKilometer ? .on : .off,
                     handler: { _ in
                         updateLocationAccuracy(kCLLocationAccuracyKilometer)
                     }),
            UIAction(title: "Within 3 Kilometers",
                     state: locationAccuracy == kCLLocationAccuracyThreeKilometers ? .on : .off,
                     handler: { _ in
                         updateLocationAccuracy(kCLLocationAccuracyThreeKilometers)
                     })
        ])
        
        return accuracyOptions
    }
    
    /// A menu for displaying the settings for location accuracy.
    private var activityTypeMenu: UIMenu {
        func updateActivity(_ newActivity: CLActivityType) {
            self.activityType = newActivity
            self.configureSettingsMenu()
        }
        
        let activityOptions = UIMenu(title: "Activity Type", options: .displayInline, children: [
            UIAction(title: "Automotive Navigation",
                     state: activityType == CLActivityType.automotiveNavigation ? .on : .off,
                     handler: { _ in
                         updateActivity(CLActivityType.automotiveNavigation)
                     }),
            UIAction(title: "Fitness (Walking, Running, Biking)",
                     state: activityType == CLActivityType.fitness ? .on : .off,
                     handler: { _ in
                         updateActivity(CLActivityType.fitness)
                     }),
            UIAction(title: "Other Activity",
                     state: activityType == CLActivityType.other ? .on : .off,
                     handler: { _ in
                         updateActivity(CLActivityType.other)
                     })
        ])
        
        return activityOptions
    }
    
    /// Attaches a menu to the settings button, with the configured menu items for the current state of the app.
    func configureSettingsMenu() {
        settingsButton.menu = UIMenu(title: "Settings", children: [
            mapSettingsMenu,
            audioSettingsMenu,
            locationAccuracyMenu,
            activityTypeMenu
        ])
    }
    
    /// Configures the recording menu in the navigation bar.
    func configureRecordingMenu() {
        let recordingActionHandler = { (action: UIAction) in
            if self.isMonitoringLocation {
                self.stopRecordingLocation()
            } else {
                self.startRecordingLocation()
            }

            self.configureRecordingMenu()
        }
        
        recordButton.image = recordButtonImage
        recordButton.menu = UIMenu(title: "Record Path", children: [
            UIAction(title: isMonitoringLocation ? "Stop Recording" : "Start Recording",
                     image: recordButtonImage,
                     handler: recordingActionHandler)
        ])
    }
    
    private var recordButtonImage: UIImage? {
        return UIImage(systemName: isMonitoringLocation ? "stop.circle.fill" : "record.circle")
    }
}
