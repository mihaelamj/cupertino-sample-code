/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the current zoom value.
*/

import SwiftUI

/// A view that displays the current zoom value.
struct ZoomView: View {
    let zoomValue: Double
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        Text(String(format: "%0.1fx", zoomValue))
            .padding(10)
            .background(.black.opacity(0.3))
            .foregroundColor(.yellow)
            .font(.system(size: 18))
            .clipShape(Circle())
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

#Preview {
    ZoomView(zoomValue: 1.0)
}
