/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This shows an example of how to implement a custom overlay for data that you can't represent with MapKit's
 overlay classes.
*/

import Foundation
import CoreLocation
import MapKit

/**
 The `PeakGroundAccelerationGrid` is a model object representing a value for how much the ground might accelerate during
 an earthquake. The acceleration is a floating-point number, with each acceleration data point aligning to an evenly spaced grid of coordinates.
 */
class PeakGroundAccelerationGrid: MKShape, MKOverlay {
    
    typealias Acceleration = Double
    
    /// The bounds of this overlay, expressed using grid geometry.
    private var boundingGridRect: GridRect!
    
    /// The distance between every coordinate in the grid, for both latitude and longitude spacing.
    private(set) var gridSpacing: GridDegrees
    
    /// The acceleration data for every coordinate in the data file.
    private(set) var dataPoints = [GridCoordinate: Acceleration]()
    
    /// Loads the data from the URL. This function is async because loading the data may take some time.
    init?(gridedDataFile: URL) async {
        var rawData: String!
        var spacing: GridDegrees = 0
        
        do {
            rawData = try String(contentsOf: gridedDataFile)
        } catch {
            debugPrint(error)
            return nil
        }

        /**
         The input data file needs to have three columns per line in the following order:
         longitude    latitude    acceleration
        
         Each line has an arbitrary amount of whitespace between the values.
         The first line of the data needs to be the top left coordinate of the bounded area,
         and the last line of the data is the bottom right coordinate.
         */
        let scanner = Scanner(string: rawData)
        var topLeft: GridCoordinate!
        var bottomRight: GridCoordinate!
        while !scanner.isAtEnd {
            // Read the latitude and longitude as `Decimal` instead of `Double` to avoid changes to the
            // value when using a floating-point representation.
            if let longitude = scanner.scanDecimal(),
               let latitude = scanner.scanDecimal(),
               let acceleration = scanner.scanDouble() {
                
                let location = GridCoordinate(latitude: latitude, longitude: longitude)
                
                if topLeft != nil, spacing == 0 {
                    // After reading two lines of the file, this class can determine the size of the grid spacing.
                    spacing = location.longitude - topLeft.longitude
                } else if topLeft == nil {
                    // After reading the first line, this class determines the top left coordinate.
                    topLeft = location
                }
                 
                /**
                 The scanner can't determine where the end of the file is until it reaches it. Assume every line it reads is the last line of the
                 file, and use that value to define the bottom-right coordinate of the bounding region.
                */
                bottomRight = location
                
                dataPoints[location] = acceleration
            }
        }
        
        boundingGridRect = GridRect(origin: topLeft, extent: bottomRight)
        
        gridSpacing = spacing
        
        super.init()
        
        /**
         This class inherits from `MKShape`, which adopts the `MKAnnotation` protocol. This allows you to use a custom overlay as both an
         overlay and an annotation.
         */
        title = "Peak Earthquake Ground Acceleration"
    }
    
    /**
     Custom implementations of `MKOverlay` need to provide properties for the center and bounding map rectangle
     of the overlay so that MapKit can determine what portion of the map the overlay covers, and when to draw the overlay contents.
     */
    // MARK: - MKOverlay Conformance
    
    /// The center of the bounding region that the data covers.
    override var coordinate: CLLocationCoordinate2D {
        let xPoint = boundingMapRect.origin.x + (boundingMapRect.size.width / 2)
        let yPoint = boundingMapRect.origin.y + (boundingMapRect.size.height / 2)
        let mapPoint = MKMapPoint(x: xPoint, y: yPoint)
        let centerCoordinate = mapPoint.coordinate
        
        return centerCoordinate
    }
    
    /// The bounding region that the data covers.
    var boundingMapRect: MKMapRect {
        let topLeftPoint = MKMapPoint(boundingGridRect.origin.locationCoordinate)
        let bottomRightPoint = MKMapPoint(boundingGridRect.extent.locationCoordinate)
          
        let size = MKMapSize(width: bottomRightPoint.x - topLeftPoint.x, height: bottomRightPoint.y - topLeftPoint.y)
        let rect = MKMapRect(origin: topLeftPoint, size: size)
        return rect
    }
}
