/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Describes a trailhead entity.
*/

public struct Trailhead: Hashable, Sendable {
    /// The name of the rest stop.
    var name: String
    /// The name of the entity in Reality Composer Pro.
    var entityName: String
    
    init(name: String, entityName: String) {
        self.name = name
        self.entityName = entityName
    }
}
