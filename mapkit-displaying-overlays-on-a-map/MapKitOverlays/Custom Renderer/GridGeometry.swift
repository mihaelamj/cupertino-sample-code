/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file provides data types for working with map data that aligns to a grid of evenly spaced geographic coordinates.
*/

import CoreLocation
import Foundation
import MapKit

/**
 An integer-based coordinate for use when working on an evenly spaced grid of coordinates.
 The conversion of `CoreLocation` coordinates to an integer system is important for the imported
 data to avoid small deviations from the grid of evenly spaced values through accumulated errors in floating-point arithmetic.
 */
struct GridCoordinate: Hashable {
    
    let latitude: GridDegrees
    let longitude: GridDegrees
    
    init(latitude: Decimal, longitude: Decimal) {
        let decimalLatitude = NSDecimalNumber(decimal: latitude * Decimal(gridDegreeConversionFactor))
        let decimalLongitude = NSDecimalNumber(decimal: longitude * Decimal(gridDegreeConversionFactor))
        
        self.latitude = decimalLatitude.intValue
        self.longitude = decimalLongitude.intValue
    }
    
    init(latitude: GridDegrees, longitude: GridDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude.gridDegrees
        self.longitude = longitude.gridDegrees
    }
    
    init(_ mapPoint: MKMapPoint) {
        let coordinate = mapPoint.coordinate
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    var locationCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude.locationDegrees, longitude: longitude.locationDegrees)
    }

    var mapPoint: MKMapPoint {
        return MKMapPoint(locationCoordinate)
    }
    
    enum OutsetDirection {
        case upAndLeft
        case downAndRight
    }

    /**
     Adjust a coordinate's `latitude` and `longitude` so it aligns to a grid interval.
     The size of the adjustment to apply to the `latitude` and `longitude` may differ.
     */
    func outsetToNearest(_ interval: GridDegrees, direction: OutsetDirection) -> GridCoordinate {
        if direction == .upAndLeft {
            let newLat = latitude >= 0 ? latitude.roundUpToNearest(interval) : latitude.roundDownToNearest(interval)
            let newLong = longitude > 0 ? longitude.roundDownToNearest(interval) : longitude.roundUpToNearest(-interval)
            return GridCoordinate(latitude: newLat, longitude: newLong)
        } else {
            let newLat = latitude > 0 ? latitude.roundDownToNearest(-interval) : latitude.roundUpToNearest(-interval)
            let newLong = longitude >= 0 ? longitude.roundUpToNearest(interval) : longitude.roundDownToNearest(interval)
            return GridCoordinate(latitude: newLat, longitude: newLong)
        }
    }
}

// MARK: - Degrees

/// All coordinates shift from floating-point values to integers.
typealias GridDegrees = Int

/**
 The data in this sample contains two decimal places of accuracy.
 The conversion factor shifts the decimal point to convert between integers and floating-point values.
 */
private let gridDegreeConversionFactor: CLLocationDegrees = 100

extension CLLocationDegrees {
    var gridDegrees: GridDegrees {
        return GridDegrees(self * gridDegreeConversionFactor)
    }
}

extension GridDegrees {
    
    /// Shifts the value up to the nearest requested grid interval.
    func roundUpToNearest(_ interval: GridDegrees) -> GridDegrees {
        let remainder = self % interval
        let result = self + (interval - remainder)
        return result
    }
    
    /// Shifts the value down to the nearest requested grid interval.
    func roundDownToNearest(_ interval: GridDegrees) -> GridDegrees {
        let remainder = self % interval
        let result = self - remainder
        return result
    }
    
    var locationDegrees: CLLocationDegrees {
        return CLLocationDegrees(self) / gridDegreeConversionFactor
    }
}

// MARK: - Rectangles

/**
 A rectangle that the overlay expresses with two `GridCoordinate` values, the `origin` and the `extent`. This rectangle is interchangable with
 `MKMapRect` to aid drawing of the custom overlay while still maintaing integer-level coordinate values.  As a result of this interchangability with
 `MKMapRect`, the defining points of this rectangle might not align to grid interval spacing.
 */
struct GridRect {
    
    /// The upper left coordinate of the rectangle.
    let origin: GridCoordinate
    
    /// The bottom right coordinate of the rectangle.
    let extent: GridCoordinate
    
    init(from mapRect: MKMapRect) {
        origin = GridCoordinate(mapRect.origin)
        extent = GridCoordinate(MKMapPoint(x: mapRect.origin.x + mapRect.width, y: mapRect.origin.y + mapRect.height))
    }
    
    init(origin: GridCoordinate, extent: GridCoordinate) {
        self.origin = origin
        self.extent = extent
    }
    
    /**
     Expand the size of the rectangle to the nearest grid interval. The renderer uses this to align the rectangle to grid interval spacing.
     Even if the rectangle is already grid-aligned, this expands the rectangle to the next larger interval in each dimension.
     */
    func outsetToNearest(_ interval: GridDegrees) -> GridRect {
        let newOrigin = origin.outsetToNearest(interval, direction: .upAndLeft)
        let newExtent = extent.outsetToNearest(interval, direction: .downAndRight)
        
        return GridRect(origin: newOrigin, extent: newExtent)
    }
    
    var mapRect: MKMapRect {
        let origin = origin.mapPoint
        let bottomRight = extent.mapPoint
        let size = MKMapSize(width: origin.x - bottomRight.x, height: bottomRight.y - origin.y)
        let rect = MKMapRect(origin: origin, size: size)
        return rect
    }
}
