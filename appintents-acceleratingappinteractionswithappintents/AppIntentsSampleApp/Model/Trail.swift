/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data type representing the properties that the app displays for a trail.
*/

import AppIntents
import CoreLocation
import Foundation

/**
 Represents the fixed properties from `TrailData`, such as the trail name and length, but also properties that vary based on the individual,
 such as their distance to the trail.
 */
struct Trail: Identifiable, Hashable, Sendable {
    /// The trail's stable identifier.
    let id: Int
    
    /// The trail's name.
    let name: String
    
    /// The resource name of an image for the trail.
    let featuredImage: String
    
    /**
     An array of image names. The sample code doesn't use this property, but it demonstrates when to create a related structure
     conforming to `AppEntity`, rather than directly conforming to `AppEntity`. See `TrailEntity.swift`.
     */
    let recentImages = [String]()
    
    /// A description of the trail's location, such as a nearby city name or the national park encompassing it.
    let regionDescription: String
    
    /// The trail's coordinate.
    let coordinate: CLLocationCoordinate2D
    
    /// The distance to the trail from a person's location.
    let distanceToTrail: Measurement<UnitLength>
    
    /// The trail's length, in meters.
    let trailLength: Measurement<UnitLength>
    
    /// The types of activities people can do on the trail, such as hike, ski, or ride a horse.
    let activities: [ActivityStyle]
    
    /// Information on the trail's condition, such as whether it is open or closed, or contains hazards.
    let currentConditions: String
    
    init(data: TrailData, travelDistance: CLLocationDistance) {
        id = data.id
        name = data.name
        featuredImage = data.imageName
        regionDescription = data.displayLocation
        trailLength = Measurement(value: data.trailLength, unit: .meters)
        activities = data.activities
        currentConditions = data.currentConditions
        
        coordinate = CLLocationCoordinate2D(latitude: data.latitude, longitude: data.longitude)
        distanceToTrail = Measurement(value: travelDistance, unit: .meters)
    }
    
    static func == (lhs: Trail, rhs: Trail) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A type representing the fixed properties of a trail, such as its name and length, when you load them from one of the sample project files.
struct TrailData: Identifiable, Decodable {
    let id: Int
    let name: String
    let imageName: String
    let displayLocation: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let trailLength: CLLocationDistance
    let activities: [ActivityStyle]
    let currentConditions: String
}

/// A structure containing all of the sample data, to facilitate loading it into the app.
struct DataContainer: Decodable {
    let collections: [TrailCollection]
    let trails: [TrailData]
}
