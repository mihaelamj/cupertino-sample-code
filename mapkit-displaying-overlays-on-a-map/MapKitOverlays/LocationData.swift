/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file contains location points that the sample uses.
*/

import CoreLocation
import MapKit

class LocationData {
    static let paris = CLLocationCoordinate2D(latitude: 48.853_34, longitude: 2.348_79)
    
    static let ferryBuilding = CLLocationCoordinate2D(latitude: 37.795_316, longitude: -122.393_760)
    static let goldenGateBridge = CLLocationCoordinate2D(latitude: 37.810_000, longitude: -122.477_450)
    static let goldenGatePark = CLLocationCoordinate2D(latitude: 37.772_623, longitude: -122.460_217)
    static let sanFranciscoCivicCenter = CLLocationCoordinate2D(latitude: 37.779_379, longitude: -122.418_433)
    static let sanFranciscoGeographicCenter = CLLocationCoordinate2D(latitude: 37.754_48, longitude: -122.442_49)
    
    /// An array of ordered locations where a line between the points never crosses itself.
    static let orderedSanFranciscoLocations = [goldenGateBridge, ferryBuilding, sanFranciscoCivicCenter, goldenGatePark]
    
    /// An array of locations where a line between the locations crosses over itself multiple times.
    static let crossedSanFranciscoLocations = [goldenGateBridge, sanFranciscoCivicCenter, ferryBuilding, goldenGatePark]
    
    /// An array of locations connecting the Golden Gate Bridge to Golden Gate Park.
    static let sanFranciscoBridgeAndPark = [goldenGateBridge, goldenGatePark]
    
    /// The default region that the map displays.
    static let sanFranciscoDefaultRegion = MKCoordinateRegion(center: LocationData.sanFranciscoGeographicCenter,
                                                              latitudinalMeters: 45_000,
                                                              longitudinalMeters: 45_000)
    
    /// - Tag: sf_rectangle
    /// A rectangular area containing San Francisco.
    static let sanFranciscoRectangle = [
        CLLocationCoordinate2D(latitude: 37.816_41, longitude: -122.522_62),
        CLLocationCoordinate2D(latitude: 37.816_41, longitude: -122.355_54),
        CLLocationCoordinate2D(latitude: 37.702_08, longitude: -122.355_54),
        CLLocationCoordinate2D(latitude: 37.702_08, longitude: -122.522_62)
    ]
    
    /// An array of coordinates outlining the shape of Plaza de Cesar Chavez Park.
    static let plazaDeCesarChavezParkOutline = [
        CLLocationCoordinate2D(latitude: 37.332_820, longitude: -121.890_455),
        CLLocationCoordinate2D(latitude: 37.332_720, longitude: -121.890_395),
        CLLocationCoordinate2D(latitude: 37.331_450, longitude: -121.889_424),
        CLLocationCoordinate2D(latitude: 37.331_370, longitude: -121.889_320),
        CLLocationCoordinate2D(latitude: 37.331_320, longitude: -121.889_220),
        CLLocationCoordinate2D(latitude: 37.331_290, longitude: -121.889_090),
        CLLocationCoordinate2D(latitude: 37.331_310, longitude: -121.888_960),
        CLLocationCoordinate2D(latitude: 37.331_360, longitude: -121.888_880),
        CLLocationCoordinate2D(latitude: 37.331_440, longitude: -121.888_810),
        CLLocationCoordinate2D(latitude: 37.331_480, longitude: -121.888_800),
        CLLocationCoordinate2D(latitude: 37.331_560, longitude: -121.888_804),
        CLLocationCoordinate2D(latitude: 37.331_600, longitude: -121.888_820),
        CLLocationCoordinate2D(latitude: 37.333_040, longitude: -121.889_890),
        CLLocationCoordinate2D(latitude: 37.333_080, longitude: -121.889_930),
        CLLocationCoordinate2D(latitude: 37.333_110, longitude: -121.889_990),
        CLLocationCoordinate2D(latitude: 37.333_140, longitude: -121.890_100),
        CLLocationCoordinate2D(latitude: 37.333_140, longitude: -121.890_130),
        CLLocationCoordinate2D(latitude: 37.333_140, longitude: -121.890_210),
        CLLocationCoordinate2D(latitude: 37.333_120, longitude: -121.890_270),
        CLLocationCoordinate2D(latitude: 37.333_090, longitude: -121.890_340),
        CLLocationCoordinate2D(latitude: 37.333_060, longitude: -121.890_390),
        CLLocationCoordinate2D(latitude: 37.333_020, longitude: -121.890_423),
        CLLocationCoordinate2D(latitude: 37.332_960, longitude: -121.890_450),
        CLLocationCoordinate2D(latitude: 37.332_900, longitude: -121.890_467),
        CLLocationCoordinate2D(latitude: 37.332_820, longitude: -121.890_455)
    ]
    static let plazaDeCesarChavezParkCenter = CLLocationCoordinate2D(latitude: 37.332_20, longitude: -121.889_63)
    
    /// A location in a river delta that connects to San Francisco Bay.
    static let californiaDelta = CLLocationCoordinate2D(latitude: 38.047_04, longitude: -121.596_57)
    
    /// A map region encompasing a wide section of Northern California.
    static let northernCaliforniaRegion = MKCoordinateRegion(center: LocationData.californiaDelta,
                                                             span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4))
}

/**
 Consider coordinates equal within a reasonable geographic tolerance to account for minute differences in the underlying value
 due to floating-point arithmetic.
 */
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        let tolerance = 0.000_001
        let latitudeIsAlmostEqual = abs(lhs.latitude - rhs.latitude) < tolerance
        let longitudeIsAlmostEqual = abs(lhs.longitude - rhs.longitude) < tolerance
        
        return latitudeIsAlmostEqual && longitudeIsAlmostEqual
    }
}

extension MKMultiPoint {
    
    /// An array of all of the `UnsafeMutablePointer<MKMapPoint>` points in the shape converted to `[CLLocationCoordinate2D]`.
    var coordinates: [CLLocationCoordinate2D] {
        let pointData = points()
        return (0 ..< pointCount).map { pointData[$0].coordinate }
    }
}
