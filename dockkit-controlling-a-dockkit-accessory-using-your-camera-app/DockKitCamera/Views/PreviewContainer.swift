/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that provides a container view around the camera preview.
*/

import SwiftUI

// The portrait-orientation aspect ratios.
typealias AspectRatio = CGSize
let movieAspectRatio = AspectRatio(width: 9.0, height: 16.0)

/// A view that provides a container view around the camera preview.
///
/// This view applies transition effects when changing capture modes or switching devices.
/// On a compact device size, the app also uses this view to offset the vertical position
/// of the camera preview to better fit the UI when in photo-capture mode.
@MainActor
struct PreviewContainer<Content: View, CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    
    // The state values for the transition effects.
    @State private var blurRadius = CGFloat.zero
    
    private let content: Content
    
    init(camera: CameraModel, @ViewBuilder content: () -> Content) {
        self.camera = camera
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            previewView
        }
        .clipped()
        // Apply an appropriate aspect ratio based on the selected capture mode.
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
    
    /// Attach animations to the camera preview.
    var previewView: some View {
        content
            .blur(radius: blurRadius, opaque: true)
            .onChange(of: camera.isSwitchingVideoDevices, updateBlurRadius(_:_:))
    }
    
    func updateBlurRadius(_: Bool, _ isSwitching: Bool) {
        withAnimation {
            blurRadius = isSwitching ? 30 : 0
        }
    }
    
    var aspectRatio: AspectRatio {
        movieAspectRatio
    }
}
