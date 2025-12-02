/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main object.
*/

import SwiftUI

@main
struct MIDIReceiverApp: App {
    
    private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            PacketReceiverView(receiverOptions: appState.receiverOptions,
                               logModel: appState.logModel)
            .padding(EdgeInsets(top: 12.5, leading: 10.0, bottom: 25.0, trailing: 10.0))
            .onAppear {
                appState.receiverManager.startLogTimer()
            }
            .onDisappear {
                appState.receiverManager.stopLogTimer()
            }
        }
    }
    
}
