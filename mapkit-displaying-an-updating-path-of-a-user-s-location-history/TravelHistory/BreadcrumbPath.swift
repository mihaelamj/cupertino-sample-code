/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A overlay model object representing a path that changes over time.
*/

import Foundation
import MapKit
import os

// - Tag: overlay_threads
class BreadcrumbPath: NSObject, MKOverlay {
    
    /**
     The data underlying `BreadcrumbPath` needs protection from concurrent access to avoid data races. By gathering the data into a
     structure, the app treats all of the properties comprising the data as one value, and protects it with a single `OSAllocatedUnfairLock`.
     The app updates this data on the main thread, and reads it from multiple threads.
     */
    private struct BreadcrumbData {
        /// The locations in the breadcrumb path.
        var locations: [CLLocation]
     
        /// The backing storage for the path bounds.
        var bounds: MKMapRect
        
        init(locations: [CLLocation] = [CLLocation](), pathBounds: MKMapRect = MKMapRect.world) {
            self.locations = locations
            self.bounds = pathBounds
        }
    }
    
    /**
     MapKit expects an overlay's `boundingMapRect` to never change, which is why `MKOverlay` defines the property as read-only.
     Because the app continuously updates this overlay's path, this class returns `MKMapRect.world` to satisfy the never-changing
     requirement of `boundingMapRect` to the MapKit classes.
     */
    let boundingMapRect = MKMapRect.world
    
    /**
     This is a coordinate within the overlay, often the center. This overlay initalizes this property to a default value, and then
     updates it to the path's first location.
     */
    private(set) var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    /// This is a lock protecting the `locations` and `bounds` properties that define the breadcrumb path from data races.
    private let protectedBreadcrumbData = OSAllocatedUnfairLock(initialState: BreadcrumbData())
    
    /**
     This is a rectangle encompassing the breadcrumb path, including a reasonable amount of padding. The value of this property changes
     when adding a new location to the breadcrumb path that’s outside of the existing `pathBounds`.
     */
    var pathBounds: MKMapRect {
        /**
         The app accesses this property from the main thread in `BreadcrumbViewController`, and multiple
         background threads running in parallel, through the `canDraw(_:zoomScale)` method.
         Using a lock for access avoids data races.
         */
        return protectedBreadcrumbData.withLock { breadcrumbData in
            return breadcrumbData.bounds
        }
    }
    
    /// Each location in `locations` represents a single crumb in the breadcrumb path.
    var locations: [CLLocation] {
        /**
         Readers of the location data, namely, the `draw(_:zoomScale:in:)` method in `BreadcrumbPathRenderer`,
         read this data from a background thread, and may do so from multiple threads running at the same time.
         Using a lock for access avoids data races.
         */
        return protectedBreadcrumbData.withLock { breadcrumbData in
            return breadcrumbData.locations
        }
    }

    /**
     Adds a new location to the crumb path.
     - Returns: `locationAdded` is `true` if the added coordinate moves far enough from the previously added location,
     `false` if the function discards the location. `boundingRectChanged` is true when the bounds of the updated crumb path change.
     */
    func addLocation(_ newLocation: CLLocation) -> (locationAdded: Bool, boundingRectChanged: Bool) {
        /**
         This sample project delivers location updates on the main thread, though your app might do so
         on any thread. When MapKit renders the overlay, multiple background threads may be drawing
         different portions of the overlay at the same time and need the location data. Each thread needs to
         read data from this object, which could lead to a data race. Using a lock for access avoids data races.
        */
        let result = protectedBreadcrumbData.withLock { breadcrumbData in
            guard isNewLocationUsable(newLocation, breadcrumbData: breadcrumbData) else {
                let locationChanged = false
                let boundsChanged = false
                return (locationChanged, boundsChanged)
            }
            
            var previousLocation = breadcrumbData.locations.last
            if breadcrumbData.locations.isEmpty {
                coordinate = newLocation.coordinate
                
                let origin = MKMapPoint(coordinate)
                
                // The default `pathBounds` size is 1 square kilometer that centers on `coordinate`.
                let oneKilometerInMapPoints = 1000 * MKMapPointsPerMeterAtLatitude(coordinate.latitude)
                let oneSquareKilometer = MKMapSize(width: oneKilometerInMapPoints, height: oneKilometerInMapPoints)
                breadcrumbData.bounds = MKMapRect(origin: origin, size: oneSquareKilometer)
                
                // Clamp the rectangle to be within the world.
                breadcrumbData.bounds = breadcrumbData.bounds.intersection(.world)
                
                // For the first location in the array, fake a previous location so that calculating the bounds
                // change has something to compare against.
                previousLocation = newLocation
            }
            
            breadcrumbData.locations.append(newLocation)
            
            // Compute the `MKMapRect` bounding the most recent location, and the new location.
            let pointSize = MKMapSize(width: 0, height: 0)
            let newPointRect = MKMapRect(origin: MKMapPoint(newLocation.coordinate), size: pointSize)
            let prevPointRect = MKMapRect(origin: MKMapPoint(previousLocation!.coordinate), size: pointSize)
            let pointRect = newPointRect.union(prevPointRect)
            
            // Update the `pathBounds` to hold the new location, if needed.
            var boundsChanged = false
            let locationChanged = true
            if !breadcrumbData.bounds.contains(pointRect) {
                /**
                 Extends `pathBounds` to include the contents of `rect`, plus some additional padding.
                 The padding allows for the bounding rectangle to only grow sporadically, rather than after adding nearly
                 every additional point to the crumb path.
                 */
                var grownBounds = breadcrumbData.bounds.union(pointRect)
                
                /**
                 The number of map points per unit of distance varies based on latitude. To grow the bounds exactly by 1 kilometer,
                 each edge of the bounds needs to change by a different amount of map points. The padding amount doesn't
                 need to be exactly 1 kilometer, so instead, determine the number of map points at the new rectangle's latitude
                 and use this value for the padding amount for all edges, even though it doesn't represent exactly 1 kilometer.
                */
                let paddingAmountInMapPoints = 1000 * MKMapPointsPerMeterAtLatitude(pointRect.origin.coordinate.latitude)
                
                // Grow by an extra kilometer in the direction of the overrun.
                if pointRect.minY < breadcrumbData.bounds.minY {
                    grownBounds.origin.y -= paddingAmountInMapPoints
                    grownBounds.size.height += paddingAmountInMapPoints
                }
                
                if pointRect.maxY > breadcrumbData.bounds.maxY {
                    grownBounds.size.height += paddingAmountInMapPoints
                }
                
                if pointRect.minX < breadcrumbData.bounds.minX {
                    grownBounds.origin.x -= paddingAmountInMapPoints
                    grownBounds.size.width += paddingAmountInMapPoints
                }
                
                if pointRect.maxX > breadcrumbData.bounds.maxX {
                    grownBounds.size.width += paddingAmountInMapPoints
                }
                
                // Ensure the updated `pathBounds` is never larger than the world size.
                breadcrumbData.bounds = grownBounds.intersection(.world)
                boundsChanged = true
            }
            
            return (locationChanged, boundsChanged)
        }
        
        return result
    }
    
    /// Filter out any locations that are anomalous so that the app doesn't include them in the breadcrumb data.
    // - Tag: filter_locations
    private func isNewLocationUsable(_ newLocation: CLLocation, breadcrumbData: BreadcrumbData) -> Bool {
        /**
         Always check the timestamp of a location value to ensure the location is recent, such as within the last 60 seconds. When starting
         location updates, the values that return may reflect cached values while the device works to acquire updated locations according to
         the accuracy level of the location manager. For some apps, the cached values may be sufficient, but in an app that draws a map of
         a user's travel path, values that are too old may deviate too far from the user's actual path.
         */
        let now = Date()
        let locationAge = now.timeIntervalSince(newLocation.timestamp)
        guard locationAge < 60 else { return false }
        
        /**
         An app might keep the first few updates before applying any further filtering, such as to ensure there is an intial set of
         locations while waiting for the location accuracy to increase to the requested level.
         */
        guard breadcrumbData.locations.count > 10 else { return true }
        
        /**
         Identify locations that shouldn't be part of the breadcrumb data, such as locations that are too close together.
         Get the distance between this new location and the previous location, and use a minimum threshold
         to determine if keeping the location is useful. For example, a location update that is just a few meters from the
         prior location might represent a user that hasn't moved.
         
         Your app may apply other criteria. For example, an app tracking a user at walking speed may discard updates that show the user
         moving at car speeds because that might indicate the user forgot to stop recording their location after completing the walk.
         Consider comparing an average value over the last several location updates, such as the user's average speed.
         
         If using the location accuracy properties as criteria for determining a usable location, expect the values to vary, and don't
         throw away low-accuracy values by expecting only high-accuracy values. Discarding locations due to lower than expected accuracy
         can cause the user's location to appear to jump if the user is moving.
         */
        let minimumDistanceBetweenLocationsInMeters = 10.0
        let previousLocation = breadcrumbData.locations.last!
        let metersApart = newLocation.distance(from: previousLocation)
        return metersApart > minimumDistanceBetweenLocationsInMeters
    }
}
