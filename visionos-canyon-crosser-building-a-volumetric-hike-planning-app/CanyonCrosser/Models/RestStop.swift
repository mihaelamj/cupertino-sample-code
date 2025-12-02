/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Describes a rest stop on a hike.
*/

public struct RestStop: Hashable, Sendable {
    /// The name of the rest stop.
    let name: String
    /// The name of the entity in Reality Composer Pro.
    let entityName: String

    /// During a hike, the hiker may have several opportunities to rest at a rest stop, if the hiker passes by the rest stop several times.
    /// A rest stop may have several rest stop options at different trail completion percentages.
    let locations: [RestStopLocation]

    /// The description of the rest stop.
    let description: String
    
    public init(name: String, entityName: String, locations: [RestStopLocation], description: String) {
        self.name = name
        self.entityName = entityName
        self.locations = locations
        self.description = description
    }
}
