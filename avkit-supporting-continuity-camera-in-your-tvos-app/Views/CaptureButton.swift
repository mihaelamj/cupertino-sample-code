/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button with camera shutter styles and animation.
*/

import SwiftUI

/// A button that mimics the style of the iOS Camera app shutter button.
struct CaptureButton: View {

    /// The action to perform when a person presses the button.
    var action: () -> Void

    @Binding var captureType: CaptureType

    var captureState: CaptureState?

    private var fillColor: Color {
        (captureType == .photo) ? .white : .accentColor
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .stroke(lineWidth: 5)
                    .foregroundColor(.white)
                if case .recording = captureState {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(fillColor)
                        .padding(15)
                } else {
                    Circle()
                        .fill(fillColor)
                        .padding(5)
                }
            }
            .frame(width: 65, height: 65)
            .aspectRatio(1.0, contentMode: .fit)
        }
    }
}

// MARK: -

struct ShutterButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CaptureButton(action: {}, captureType: .constant(.photo), captureState: .none)
            CaptureButton(action: {}, captureType: .constant(.video), captureState: .recording(startTime: .now))
        }
    }
}
