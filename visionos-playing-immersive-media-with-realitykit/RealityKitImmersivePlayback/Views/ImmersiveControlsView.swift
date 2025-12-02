/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A container for controls visible during immersive playback.
*/

import RealityKit
import SwiftUI

struct ImmersiveControlsView: View {
    let comfortMitigation: VideoPlayerComponent.VideoComfortMitigation?

    var body: some View {
        VStack(alignment: .center) {
            if let message = comfortMitigation?.displayMessage {
                Text(message)
                    .glassBackgroundEffect(.feathered)
            }
            TransportView(isCloseButtonVisible: true)
        }
    }
}
