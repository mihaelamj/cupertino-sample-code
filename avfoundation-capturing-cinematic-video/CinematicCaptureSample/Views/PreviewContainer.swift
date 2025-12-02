/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that provides a container view around the camera preview.
*/

import SwiftUI

// Portrait-orientation aspect ratios.
typealias AspectRatio = CGSize
let movieAspectRatio = AspectRatio(width: 9.0, height: 16.0)

/// A view that provides a container view around the camera preview.
///
/// This view applies transition effects when changing capture modes or switching devices.
@MainActor
struct PreviewContainer<Content: View, CameraModel: Camera>: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    // State values for transition effects.
    @State private var blurRadius = CGFloat.zero
    
    private let content: Content
    
    init(camera: CameraModel, @ViewBuilder content: () -> Content) {
        self.camera = camera
        self.content = content()
    }
    
    var body: some View {
        // On compact devices, show a view finder rectangle around the video preview bounds.
        if horizontalSizeClass == .compact {
            ZStack {
                previewView
            }
            .clipped()
            // Apply an appropriate aspect ratio based on the selected capture mode.
            .aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            // On regular-sized UIs, show the content in full screen.
            previewView
        }
    }
    
    /// Attach animations to the camera preview.
    var previewView: some View {
        content
            .blur(radius: blurRadius, opaque: false)
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
