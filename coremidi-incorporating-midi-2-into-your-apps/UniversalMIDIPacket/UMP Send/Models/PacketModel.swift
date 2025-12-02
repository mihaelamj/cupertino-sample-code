/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model describing an entire MIDI packet or message.
*/

import Foundation
import SwiftUI

class PacketModel: Identifiable, ObservableObject {
    
    let id = UUID()
    @Published var statusIndex = 0

    var status: MIDIMessageStatus {
        MIDIMessageStatus.allCases[statusIndex]
    }
    
    private var elementPairs = [MIDIMessageStatus: [PacketChunk]]()
    var chunks: [PacketChunk] {
        guard let packetChunks = elementPairs[status] else { return [] }
        return packetChunks
    }

    var sizeInBits = 0
    var attributeItems: [String] {
        MIDIAttributes.allCases.map { return $0.description }
    }
    
    var hexString: String {
        var value = String()
        for chunk in chunks {
            value += chunk.rawHex
        }
        return value
    }
    
    var sendCallback: (() -> Void)?
    
    init() {
        buildPacketDescriptions()
    }
    
    init(statusByte: UInt8, protocolID: MIDIProtocolID) {
        buildPacketDescriptions()
        let target = MIDIMessageStatus(byteValue: statusByte, protocolID: protocolID)
        for (index, element) in MIDIMessageStatus.allCases.enumerated() where element == target {
            statusIndex = index
            break
        }
    }

    private func addChunkList(_ status: MIDIMessageStatus, list: [PacketChunk]) {

        elementPairs[status] = list

        var currentBit = 0
        for chunk in list {
            let size = chunk.sizeInBits
            let startBit = currentBit
            let endBit = (startBit + size)

            chunk.range = (startBit..<endBit)
            
            currentBit += size
            if chunk.name == PacketChunkDescription.status {
                chunk.decimalValue = UInt64(status.byteValue)
            }
        }
    }
    
    private func buildPacketDescriptions() {
        
        // Build a MIDI 1 note on description.
        var chunkList = [PacketChunk(name: .mtNibble, sizeInBits: 4, defaultValue: 2),
                         PacketChunk(name: .group, sizeInBits: 4, editable: true, uiType: .indexedRaw()),
                         PacketChunk(name: .status, sizeInBits: 4),
                         PacketChunk(name: .channel, sizeInBits: 4, editable: true, uiType: .indexedRaw()),
                         PacketChunk(name: .noteNumber, sizeInBits: 8, editable: true, uiType: .indexedRaw(), definedMax: 127),
                         PacketChunk(name: .velocity, sizeInBits: 8, editable: true, uiType: .slider01, definedMax: 127)]
        addChunkList(MIDIMessageStatus.noteOn(._1_0), list: chunkList)
        
        // Build a MIDI 2 note on description.
        chunkList = [PacketChunk(name: .mtNibble, sizeInBits: 4, defaultValue: 4),
                     PacketChunk(name: .group, sizeInBits: 4, editable: true, uiType: .indexedRaw()),
                     PacketChunk(name: .status, sizeInBits: 4),
                     PacketChunk(name: .channel, sizeInBits: 4, editable: true, uiType: .indexedRaw()),
                     PacketChunk(name: .noteNumber, sizeInBits: 8, editable: true, uiType: .indexedRaw(), definedMax: 127),
                     PacketChunk(name: .attributeType, sizeInBits: 8, editable: true, uiType: .indexedNamed(attributeItems)),
                     PacketChunk(name: .velocity, sizeInBits: 16, editable: true, uiType: .slider01),
                     PacketChunk(name: .attribute, sizeInBits: 16, editable: true, uiType: .slider01)]
        addChunkList(MIDIMessageStatus.noteOn(._2_0), list: chunkList)
        
        // Build a MIDI 2 note off description.
        chunkList = [PacketChunk(name: .mtNibble, sizeInBits: 4, defaultValue: 4),
                     PacketChunk(name: .group, sizeInBits: 4, editable: true, uiType: .indexedRaw()),
                     PacketChunk(name: .status, sizeInBits: 4),
                     PacketChunk(name: .channel, sizeInBits: 4, editable: true, uiType: .indexedRaw()),
                     PacketChunk(name: .noteNumber, sizeInBits: 8, editable: true, uiType: .indexedRaw(), definedMax: 127),
                     PacketChunk(name: .attributeType, sizeInBits: 8, editable: true, uiType: .indexedNamed(attributeItems)),
                     PacketChunk(name: .velocity, sizeInBits: 16, editable: true, uiType: .slider01),
                     PacketChunk(name: .attribute, sizeInBits: 16, editable: true, uiType: .slider01)]
        addChunkList(MIDIMessageStatus.noteOff(._2_0), list: chunkList)

        // Build a MIDI 2 control change description.
        chunkList = [PacketChunk(name: .mtNibble, sizeInBits: 4, defaultValue: 4),
                     PacketChunk(name: .group, sizeInBits: 4, editable: true, uiType: .indexedRaw()),
                     PacketChunk(name: .status, sizeInBits: 4),
                     PacketChunk(name: .channel, sizeInBits: 4, editable: true, uiType: .indexedRaw()),
                     PacketChunk(name: .index, sizeInBits: 8, editable: true, uiType: .indexedRaw()),
                     PacketChunk(name: .reserved, sizeInBits: 8),
                     PacketChunk(name: .data, sizeInBits: 32, editable: true, uiType: .slider01)]
        addChunkList(MIDIMessageStatus.controlChange(._2_0), list: chunkList)

        // Build a MIDI 2 program change description.
        chunkList = [PacketChunk(name: .mtNibble, sizeInBits: 4),
                     PacketChunk(name: .group, sizeInBits: 4, editable: true, uiType: .indexedRaw()),
                     PacketChunk(name: .status, sizeInBits: 4),
                     PacketChunk(name: .channel, sizeInBits: 4, editable: true, uiType: .indexedRaw()),
                     PacketChunk(name: .reserved, sizeInBits: 8),
                     PacketChunk(name: .optionsFlags, sizeInBits: 7),
                     PacketChunk(name: .bankValidBit, sizeInBits: 1, editable: true, uiType: .toggle),
                     PacketChunk(name: .program, sizeInBits: 8, editable: true, uiType: .indexedRaw()),
                     PacketChunk(name: .reserved, sizeInBits: 8),
                     PacketChunk(name: .bankMSB, sizeInBits: 8, editable: true, uiType: .numberEntry),
                     PacketChunk(name: .bankLSB, sizeInBits: 8, editable: true, uiType: .numberEntry)]
        addChunkList(MIDIMessageStatus.programChange(._2_0), list: chunkList)
    }
    
    func getChunk(_ description: PacketChunkDescription) -> PacketChunk? {
        guard let chunk = (chunks.first { return $0.name == description }) else { return nil }
        return chunk
    }

    // MARK: - Clipboard

    private func storeInClipboard(_ value: String) {
        #if os(OSX)
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(value, forType: .string)
        #elseif os(iOS)
            let pasteboard = UIPasteboard.general
            pasteboard.string = value
        #endif
    }
    
    // MARK: - Hex
    
    func copyHexToClipboard() {
        let value = hexString
        print("Copy the hex \(value) to the clipboard.")
        storeInClipboard(value)
    }
    
}
