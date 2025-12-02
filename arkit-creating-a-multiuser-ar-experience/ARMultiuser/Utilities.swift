/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience extensions on system types.
*/

import simd
import ARKit

extension ARFrame.WorldMappingStatus {
    public var description: String {
        switch self {
        case .notAvailable:
            return "Not Available"
        case .limited:
            return "Limited"
        case .extending:
            return "Extending"
        case .mapped:
            return "Mapped"
        @unknown default:
            return "Unknown"
        }
    }
}
