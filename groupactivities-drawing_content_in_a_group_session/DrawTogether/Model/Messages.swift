/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The messages between multiple participants in a group session.
*/

import Foundation
import SwiftUI

struct UpsertStrokeMessage: Codable {
    let id: UUID
    let color: Stroke.Color
    let point: CGPoint
}

struct CanvasMessage: Codable {
    let strokes: [Stroke]
    let pointCount: Int
}

struct ImageMetadataMessage: Codable {
    let location: CGPoint
}
