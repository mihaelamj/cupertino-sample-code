/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Exposes the render duration as a `TimeInterval`.
*/

import CompositorServices

extension LayerRenderer.Clock.Instant.Duration {
    ///Exposes the render duration as a `TimeInterval`.
    var timeInterval: TimeInterval {
        let nanoseconds = TimeInterval(components.attoseconds / 1_000_000_000)
        return TimeInterval(components.seconds) + (nanoseconds / TimeInterval(NSEC_PER_SEC))
    }
}
