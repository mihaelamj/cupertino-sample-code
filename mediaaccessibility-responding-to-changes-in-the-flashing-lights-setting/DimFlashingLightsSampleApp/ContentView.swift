/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's root view.
*/

import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var playerManager = PlayerManager()
    @State private var showAlert = true
    
    /// - Tag: CreateUI
    var body: some View {
        VStack {
            Text("Video Player")
                .font(.title)
                .padding([.top, .bottom])
            Text("The following video contains sequences of flashing effects.")
                .font(.caption)
                .multilineTextAlignment(.center)
            VideoPlayer(player: playerManager.player)
                .aspectRatio(16 / 9, contentMode: .fit)
            Spacer()
            
            // Checks the status of the Dim Flashing Lights setting to determine
            // whether to draw the custom media timeline.
            if playerManager.dimFlashingLightsStatus {
                VStack {
                    Text("Custom Media Timeline")
                        .font(.title2)
                        .padding(.bottom)
                    GeometryReader { proxy in
                        // Draws a timeline view that's the same width as the
                        // video player.
                        FlashingTimelineView(proxy.size.width)
                        
                        // Draws a custom playback indicator on top of the
                        // timeline view.
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.black)
                            .border(.white)
                            .position(x: playerManager.playbackPercentage * proxy.size.width)
                            .frame(width: 9, height: 9)
                    }
                }
                .padding(.top)
            }
        }
        .padding()
        .alert(
            "Dim Flashing Lights",
            isPresented: $showAlert
        ) {
            Button("Go to Settings") {
                if let settings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settings)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("""
            To observe changes to the app's behavior, turn on \
            Settings > Accessibility > Motion > Dim Flashing Lights
            """)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
