/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Describes a hike.
*/

import simd

public struct Hike: Hashable, Sendable {
    /// Name of the hike.
    public let name: String
    /// Description of the hike.
    public let description: String
    /// Reality Composer Pro name of the trail entity.
    public let trailEntityPath: String
    /// Image to be featured in the popover.
    public let featuredImageName: String
    /// Reality Composer Pro entity name for trail start.
    public let trailStartEntityName: String
    /// Reality Composer Pro entity name for trail end.
    public let trailEndEntityName: String
    /// Length of the trail in miles.
    public let length: Double
    /// Trailhead for the hike.
    public let trailhead: Trailhead
    /// Rest stops on the trail.
    public let restStops: [RestStop]

    init(
        name: String,
        description: String,
        trailEntityPath: String,
        featuredImageName: String,
        trailStartEntityName: String,
        trailEndEntityName: String,
        length: Double,
        trailhead: Trailhead,
        restStops: [RestStop] = []
    ) {
        self.name = name
        self.description = description
        self.trailEntityPath = trailEntityPath
        self.featuredImageName = featuredImageName
        self.trailStartEntityName = trailStartEntityName
        self.trailEndEntityName = trailEndEntityName
        self.length = length
        self.trailhead = trailhead
        self.restStops = restStops
    }
}
