/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions on Entity.
*/

import AVFoundation
import RealityKit

extension Entity {
    func makeVideoPlayerComponent(with player: AVPlayer, modes: VideoModes) {
        var videoPlayer = videoPlayerComponent ?? VideoPlayerComponent(avPlayer: player)
        applyVideoModes(modes, to: &videoPlayer)
    }

    func applyVideoModes(_ modes: VideoModes, to videoPlayerComponent: inout VideoPlayerComponent) {
        if let immersiveViewingMode = modes.immersiveViewingMode {
            videoPlayerComponent.desiredImmersiveViewingMode = immersiveViewingMode
        }

        if let spatialVideoMode = modes.spatialVideoMode {
            videoPlayerComponent.desiredSpatialVideoMode = spatialVideoMode
        }

        if let viewingMode = modes.viewingMode {
            videoPlayerComponent.desiredViewingMode = viewingMode
        }

        components[VideoPlayerComponent.self] = videoPlayerComponent
    }

    func resetVideoPlayerComponent() {
        components[VideoPlayerComponent.self] = nil
    }

    func scaleToFit(_ currentSize: SIMD2<Float>, within targetSize: SIMD3<Float>) {
        let prevailingScale = min(targetSize.x / currentSize.x, targetSize.y / currentSize.y)
        scale = SIMD3<Float>(repeating: prevailingScale)
    }

    var videoPlayerComponent: VideoPlayerComponent? {
        return components[VideoPlayerComponent.self]
    }
}
