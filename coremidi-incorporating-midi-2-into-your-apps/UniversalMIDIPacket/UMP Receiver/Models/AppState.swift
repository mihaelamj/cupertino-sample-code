/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MIDI-CI discovery app state object.
*/

import Foundation

// MARK: - AppState

class AppState {
    
    let receiverOptions: ReceiverOptions
    let logModel: LogModel
    let receiverManager: PacketReceiver
    
    init(receiverOptions: ReceiverOptions = .init(), logModel: LogModel = .init()) {
        self.receiverOptions = receiverOptions
        self.logModel = logModel
        self.receiverManager = PacketReceiver(receiverOptions: receiverOptions, logModel: logModel)
    }
    
}
