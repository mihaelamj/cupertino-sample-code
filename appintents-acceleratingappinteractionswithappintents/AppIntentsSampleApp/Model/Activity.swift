/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure with the details of a person's activity.
*/

import Foundation

/// A record of when a person did an activity on a trail, and how long it took to complete.
struct Activity: Identifiable, Codable {
    let id: UUID
    let style: ActivityStyle
    let trail: Trail.ID
    let start: Date
    var end: Date?
}
