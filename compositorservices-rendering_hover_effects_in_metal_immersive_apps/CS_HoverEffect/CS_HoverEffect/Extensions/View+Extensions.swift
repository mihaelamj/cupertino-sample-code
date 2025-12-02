/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Useful utility functions for SwiftUI views.
*/
import SwiftUI
import RealityKit

import CompositorServices

import ModelIO
import ARKit
import MetalKit

extension View {
    
    /// Returns the view with a tooltip.
    /// - Parameters:
    ///   - value: The tooltip text.
    ///   - enabled: The tooltip is only visible when `true`.
    @ViewBuilder
    func help(_ value: String, enabled: Bool) -> some View {
        if enabled {
            self.help(value)
        } else {
            self
        }
    }
    
    /// Returns the view with a tooltip, which is only available in visionOS 26 and later.
    func enableOnlyOnVisionOS26() -> some View {
        return self
            .disabled({
                if #available(visionOS 26.0, *) {
                    return false
                } else {
                    return true
                }
            }())
    }
}
