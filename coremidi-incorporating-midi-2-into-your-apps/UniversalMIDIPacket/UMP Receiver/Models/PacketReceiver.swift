/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MIDI send app's packet receiver object.
*/

import Foundation
import CoreMIDI

class PacketReceiver: NSObject {
 
    private var receiverOptions: ReceiverOptions
    private var logModel: LogModel

    private var timer: Timer?

    private let midiAdapter = MIDIAdapter(logging: true)
    
    private var client = MIDIClientRef()
    private var destination = MIDIEndpointRef()
    
    private var hasDestination = false
    
    init(receiverOptions: ReceiverOptions, logModel: LogModel) {
        self.receiverOptions = receiverOptions
        self.logModel = logModel
        super.init()
        setupMIDIClient()
        setupModel()
    }
    
    private func setupMIDIClient() {
        let status = MIDIClientCreateWithBlock("Packet Receiver" as CFString, &client) { _ in }
        if status != noErr {
            print("Failed to create the MIDI client.")
            return
        }
    }
    
    private func setupModel() {
        receiverOptions.createMIDIDestination = { [weak self] in
            guard let self = self else { return }

            if self.hasDestination {
                MIDIEndpointDispose(self.destination)
            }
            
            guard let protocolID = MIDIProtocolID(rawValue: self.receiverOptions.protocolID) else { return }
            
            let destinationName = self.receiverOptions.destinationName
            let status = self.midiAdapter.createMIDIDestination(self.client,
                                                                named: destinationName as CFString,
                                                                protocol: protocolID,
                                                                dest: &self.destination)
            if status == noErr {
                self.logModel.print("Successfully created the \(protocolID.description) destination with the name \(destinationName).")
                self.hasDestination = true
            } else {
                self.logModel.print("Failed to create the \(protocolID.description) destination.")
            }
        }
    }
    
    // MARK: - Timer Callback
    
    func startLogTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self = self else { return }

            self.midiAdapter.popDestinationMessages { packet in
                self.logModel.print("------------------------------------")
                self.logModel.print("Universal MIDI Packet \(packet.wordCount * 32)")
                self.logModel.print("Data: 0x\(packet.hexString)")
                self.logModel.print(packet.description)
                self.logModel.print("")
            }
        }
    }
    
    func stopLogTimer() {
        guard let timer = self.timer else { return }
        
        timer.invalidate()
        self.timer = nil
    }
    
}
