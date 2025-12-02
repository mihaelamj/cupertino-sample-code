/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A landmark in the carousel.
*/

import Foundation
import SwiftUI

struct CarouselItem: Identifiable, Hashable, Equatable, Animatable {
    let id = UUID()
    /// The name of the landmark to display on the label.
    let name: String
    /// The country the landmark is in to display on the label.
    let country: String
    /// The z position relative to the back of the volume.
    var zPosition: Double = 0.0
    /// The name of the entity in Reality Composer Pro.
    let entityName: String
    
    init(name: String, country: String, entityName: String) {
        self.name = name
        self.country = country
        self.entityName = entityName
    }
}
