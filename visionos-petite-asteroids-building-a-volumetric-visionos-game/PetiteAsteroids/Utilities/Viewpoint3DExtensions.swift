/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions for working with viewpoints.
*/

import SwiftUI

extension Viewpoint3D {
    var angle: Float {
        switch self.squareAzimuth {
            case .front:
                0
            case .right:
                .pi / 2
            case .back:
                .pi
            case .left:
                -.pi / 2
        }
    }
}
