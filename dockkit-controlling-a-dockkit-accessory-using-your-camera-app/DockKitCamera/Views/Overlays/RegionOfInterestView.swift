/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the region-of-interest rectangle.
*/

import SwiftUI

/// A view that displays the region-of-interest rectangle.
struct RegionOfInterestView<DockControllerModel: DockController>: View {
    
    @Binding var regionOfInterest: CGRect
    @State var dockController: DockControllerModel
    
    @State private var rotationAngle: Double = 0
    @State private var textIsVisible = true
    
    var body: some View {
        @Bindable var features = dockController.dockAccessoryFeatures
        ZStack {
            ZStack {
                Rectangle()
                    .foregroundColor(.black.opacity(0.4))
                    .allowsHitTesting(false)
                Rectangle()
                    .path(in: regionOfInterest)
                    .blendMode(.destinationOut)
                    .allowsHitTesting(false)
            }
            .onChange(of: features.isSetROIEnabled) { _, newValue in
                if newValue == false {
                    regionOfInterest = CGRect.null
                }
            }
            .hidden(features.isSetROIEnabled == false || regionOfInterest == CGRect.null)
        }.overlay(alignment: .center) {
            if textIsVisible {
                Text("Touch and drag to select a region to track")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .padding()
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.easeInOut, value: rotationAngle)
                    .onAppear {
                        // Enable device-orientation monitoring.
                        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                        updateRotationAngle()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                        updateRotationAngle()
                    }
            }
        }
        .hidden(features.isSetROIEnabled == false)
        .onChange(of: features.isSetROIEnabled) {
            textIsVisible = true
            // Hide the view after 5 seconds.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    textIsVisible = false
                }
            }
        }
    }
    
    private func updateRotationAngle() {
        let orientation = UIDevice.current.orientation
        
        switch orientation {
        case .portrait:
            rotationAngle = 0
        case .landscapeLeft:
            rotationAngle = 90
        case .landscapeRight:
            rotationAngle = -90
        case .portraitUpsideDown:
            rotationAngle = 180
        default:
            rotationAngle = 0
        }
    }
}
