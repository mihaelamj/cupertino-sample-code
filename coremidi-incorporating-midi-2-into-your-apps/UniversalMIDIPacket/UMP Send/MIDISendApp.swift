/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main object.
*/

import SwiftUI

@main
struct MIDIReceiver: App {
    
    private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            PacketSenderView(packetModel: appState.packetModel,
                             logModel: appState.logModel,
                             endpointManager: appState.endpointManager)
            .padding(EdgeInsets(top: 12.5, leading: 25.0, bottom: 25.0, trailing: 25.0))
        }
    }
    
}
