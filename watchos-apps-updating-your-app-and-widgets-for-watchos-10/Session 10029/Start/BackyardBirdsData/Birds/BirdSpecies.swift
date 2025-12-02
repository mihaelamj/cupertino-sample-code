/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The bird species.
*/

import Observation
import Foundation
import SwiftData

@Model public final class BirdSpecies {
    @Attribute(.unique) public var id: String
    public var naturalScale: Double = 1
    public var parts: [BirdPart]
    
    @Relationship(.cascade, inverse: \Bird.species)
    public var birds: [Bird]
    
    @Transient
    public var info: BirdSpeciesInfo { BirdSpeciesInfo(rawValue: id) }
    
    public init(info: BirdSpeciesInfo, naturalScale: Double = 1, parts: [BirdPart]) {
        self.id = info.rawValue
        self.naturalScale = naturalScale
        self.parts = parts
    }
}
