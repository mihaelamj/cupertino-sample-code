/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A card style data structure that randomizes the rotation and color of pins on the display board.
*/

import SwiftUI

struct CardStyle {
    var pinColor: Color = .blue
    var rotation: Angle = .zero
    
    static func random() -> Self {
        var rng = SystemRandomNumberGenerator()
        return random(using: &rng)
    }
    
    static func random(using rng: inout some RandomNumberGenerator) -> Self {
        Self(
            pinColor: [
                Color.blue,
                .brown,
                .green,
                .orange,
                .cyan,
                .purple,
                .red,
                .yellow
            ].shuffled(using: &rng).first!,
            rotation: .degrees(Double.random(in: -7.0...7.0, using: &rng)))
    }
}
