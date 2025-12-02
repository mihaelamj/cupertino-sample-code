/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MIDI send app's main object.
*/

import Foundation
import CoreMIDI

class PacketSender {
 
    var packetModel: PacketModel
    var logModel: LogModel
    
    let midiAdapter = MIDIAdapter()
    
    var endpointManager: MIDIEndpointManager

    var client = MIDIClientRef()
    var port = MIDIPortRef()
    
    init(packetModel: PacketModel, logModel: LogModel, endpointManager: MIDIEndpointManager) {
        self.packetModel = packetModel
        self.logModel = logModel
        self.endpointManager = endpointManager
        
        if setupMIDI() {
            setupSendCallback()
        } else {
            logModel.print("Failed to setup the Core MIDI client.")
        }
    }

    // MARK: - Set Up MIDI
    
    private func setupMIDI() -> Bool {
        let status = MIDIClientCreateWithBlock("Packet Sender" as CFString, &client, { [weak self] notification in
            self?.handleMIDI(notification)
        })
        guard status == noErr else {
            print("Failed to create the MIDI client.")
            return false
        }

        if midiAdapter.openMIDIPort(client, named: "MIDI Output Port" as CFString, port: &port) != noErr {
            print("Failed to create the MIDI port.")
            return false
        }
        return true
    }
    
    private func setupSendCallback() {
        packetModel.sendCallback = { [weak self] in
            guard let self = self else { return }

            guard let destination = self.endpointManager.currentDestination else {
                self.logModel.print("The send destination isn't valid.", printToTerm: true)
                return
            }
            
            self.didPressSend(destination)
        }
    }
    
    // MARK: - MIDI Notification
    
    func handleMIDI(_ notification: UnsafePointer<MIDINotification>) {
        switch notification.pointee.messageID {
        case .msgObjectAdded:
            endpointManager.populateDestinations()
        case .msgSetupChanged:
            endpointManager.populateDestinations()
        case .msgObjectRemoved:
            endpointManager.populateDestinations()
        default:
            return
        }
    }

    // MARK: - User Action
    
    private func didPressSend(_ destination: MIDIEndpointRef) {
        guard let group = packetModel.getChunk(PacketChunkDescription.group)?.uint8Value,
              let channel = packetModel.getChunk(PacketChunkDescription.channel)?.uint8Value else {
            return
        }
        
        var result = noErr
        
        switch packetModel.status {
            
        case .noteOn(._1_0):
            guard let noteNumber = packetModel.getChunk(PacketChunkDescription.noteNumber)?.uint8Value,
                  let velocity = packetModel.getChunk(PacketChunkDescription.velocity)?.uint8Value else {
                        return
                    }

            result = midiAdapter.sendMIDI1UPMessage(MIDI1UPNoteOn(group,
                                                                  channel,
                                                                  noteNumber,
                                                                  velocity),
                                                    port: port,
                                                    destination: destination)
        
        case .noteOn(._2_0):
            guard let noteNumber = packetModel.getChunk(PacketChunkDescription.noteNumber)?.uint8Value,
                  let attributeType = packetModel.getChunk(PacketChunkDescription.attributeType)?.uint8Value,
                  let attributeData = packetModel.getChunk(PacketChunkDescription.attribute)?.uint16Value,
                  let velocity = packetModel.getChunk(PacketChunkDescription.velocity)?.uint16Value else {
                        return
                    }
            
            result = midiAdapter.sendMIDI2Message(MIDI2NoteOn(group,
                                                              channel,
                                                              noteNumber,
                                                              attributeType,
                                                              attributeData,
                                                              velocity),
                                                  port: port,
                                                  destination: destination)
        case .noteOff(._2_0):
                guard let noteNumber = packetModel.getChunk(PacketChunkDescription.noteNumber)?.uint8Value,
                      let attributeType = packetModel.getChunk(PacketChunkDescription.attributeType)?.uint8Value,
                      let attributeData = packetModel.getChunk(PacketChunkDescription.attribute)?.uint16Value,
                      let velocity = packetModel.getChunk(PacketChunkDescription.velocity)?.uint16Value else {
                            return
                        }
            
            result = midiAdapter.sendMIDI2Message(MIDI2NoteOff(group, channel, noteNumber, attributeType, attributeData, velocity),
                                                      port: port,
                                                      destination: destination)
            
        case .controlChange(._2_0):
                guard let index = packetModel.getChunk(PacketChunkDescription.index)?.uint8Value,
                      let value = packetModel.getChunk(PacketChunkDescription.data)?.uint32Value else {
                            return
                        }
            
            result = midiAdapter.sendMIDI2Message(MIDI2ControlChange(group, channel, index, value),
                                                      port: port,
                                                      destination: destination)
            
        case .programChange(._2_0):
                guard let bankIsValid = packetModel.getChunk(PacketChunkDescription.bankValidBit)?.boolValue,
                      let program = packetModel.getChunk(PacketChunkDescription.program)?.uint8Value,
                      let bankMSB = packetModel.getChunk(PacketChunkDescription.bankMSB)?.uint8Value,
                      let bankLSB = packetModel.getChunk(PacketChunkDescription.bankLSB)?.uint8Value else {
                            return
                        }
            
            result = midiAdapter.sendMIDI2Message(MIDI2ProgramChange(group, channel, bankIsValid, program, bankMSB, bankLSB),
                                                      port: port,
                                                      destination: destination)
            
        default:
            return
        }
        
        if result == noErr {
            logModel.print("Successfully sent the packet.", printToTerm: true)
        } else {
            logModel.print("Failed to send the packet.", printToTerm: true)
        }
    }
    
}
