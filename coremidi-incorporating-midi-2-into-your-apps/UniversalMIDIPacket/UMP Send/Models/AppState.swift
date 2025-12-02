/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The UMP send app state object.
*/

import Foundation

class AppState {
    
    var packetModel: PacketModel
    var logModel: LogModel
    var endpointManager: MIDIEndpointManager
    var packetSender: PacketSender
    
    init(packetModel: PacketModel = .init(),
         logModel: LogModel = .init(),
         endpointManager: MIDIEndpointManager = .init()) {
        self.packetModel = packetModel
        self.logModel = logModel
        self.endpointManager = endpointManager
        self.packetSender = PacketSender(packetModel: packetModel, logModel: logModel, endpointManager: endpointManager)
    }
    
}
