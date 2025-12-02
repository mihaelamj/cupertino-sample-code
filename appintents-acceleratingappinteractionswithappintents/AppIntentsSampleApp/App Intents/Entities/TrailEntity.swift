/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A trail entity that represents trail data the system retrieves from the app through an intent.
*/

import AppIntents
import Foundation

/**
 Through its conformance to `AppEntity`, `TrailEntity` represents `Trail` instances in an intent, such as a parameter.
 
 This sample implements a separate structure for `AppEntity` rather than adding conformance to the `Trail` structure. When deciding whether to
 conform an existing structure in an app to `AppEntity`, or to create a separate structure instead, consider the data that the intent uses, and
 tailor the structure to contain the minimum data required. For example, `Trail` declares a separate `recentImages` property that none of the
 intents needs. Because this property may be sizable or expensive to retrieve, the app omits this property from the definition of `TrailEntity`.
 */
struct TrailEntity: AppEntity {

    /**
     A localized name representing this entity as a concept people are familiar with in the app, including
     localized variations based on the plural rules that the app's `.stringsdict` file defines (and references
     through the `table` parameter). The app may show this value to people when they configure an intent.
     */
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Trail", table: "AppIntents"),
            numericFormat: LocalizedStringResource("\(placeholder: .int) trails", table: "AppIntents")
        )
    }
    
    /**
     Provide the system with the interface required to query `TrailEntity` structures.
     - Tag: default_query
     */
    static let defaultQuery = TrailEntityQuery()

    /// The system requires the `AppEntity` identifier to be unique and persistant because the system may save it in a shortcut.
    var id: Trail.ID
  
    // - Tag: entity_property
    /**
     The trail's name. The `EntityProperty` property wrapper makes this property's data available to the system as part of the intent,
     such as when an intent returns a trail in a shortcut.
     
     The system automatically generates the title for this property from the variable name when it displays it in a system UI, like Shortcuts.
     Generated titles are available for both `EntityProperty` and `IntentIntentParameter` property wrappers.
     */
    @Property var name: String
    
    /**
     A description of the trail's location, such as a nearby city name, or the national park encompassing it.
     
     If you want the displayed title for the property to be different from the variable name, use a `title` parameter with the
     `EntityProperty` property wrapper.
     */
    @Property(title: "Region")
    var regionDescription: String
    
    
    /// The length of the trail.
    @Property var trailLength: Measurement<UnitLength>
    
    /**
     The name of the featured image. Because people can't query for the image name in this app's intents, the app doesn't declare it as an
     `EntityProperty` with  `@Property`, and `displayRepresentation` uses the value of this property.
     */
    var imageName: String

    /// Information on the trail's condition, such as whether it's open or closed, or contains hazards.
    var currentConditions: String
    
    /**
     Information on how to display the entity to people — for example, a string like the trail name. Include the optional subtitle
     and image for a visually rich display.
     */
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)",
                              subtitle: "\(regionDescription)",
                              image: DisplayRepresentation.Image(named: imageName))
    }
    
    init(trail: Trail) {
        self.id = trail.id
        self.imageName = trail.featuredImage
        self.currentConditions = trail.currentConditions
        self.name = trail.name
        self.regionDescription = trail.regionDescription
        self.trailLength = trail.trailLength
    }
}

/**
 Integrate the app's universal links URL scheme you use with `TrailEntity`. This allows people to open the entity directly in the app using
 Universal Links. See the `OpenTrail` intent for more details.
 
 - Tag: url_entity
 */
extension TrailEntity: URLRepresentableEntity {
    static var urlRepresentation: URLRepresentation {
        // Use string interpolation to fill values from your entity necessary for constructing the universal link URL.
        // This example URL uses the unique and persistant identifier for the `TrailEntity` in the URL.
        "https://example.com/trail/\(.id)/details"
    }
}
