/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class describing a chunk of a MIDI message.
*/

import Foundation

class PacketChunk: Identifiable, ObservableObject {
    
    let id = UUID()

    let name: PacketChunkDescription
    var range = 0..<0
    let editable: Bool
    let uiType: ChunkDisplayType
    
    @Published var decimalValue = UInt64(0)
    
    var definedMax: UInt64?

    var maxDecimalValue: UInt64 {
        definedMax ?? UInt64(pow(2, Double(sizeInBits))) - 1
    }
    
    var uint8Value: UInt8 {
        assert(decimalValue <= UInt8.max)
        return UInt8(decimalValue)
    }
    
    var uint16Value: UInt16 {
        assert(decimalValue <= UInt16.max)
        return UInt16(decimalValue)
    }
    
    var uint32Value: UInt32 {
        assert(decimalValue <= UInt32.max)
        return UInt32(decimalValue)
    }

    @Published var floatValue: Float = 0.0 {
        didSet {
            var value = UInt64(floor(floatValue * Float(maxDecimalValue)))
            if value > maxDecimalValue {
                value = maxDecimalValue
            }
            decimalValue = value
        }
    }

    var boolValue: Bool {
        get {
            return decimalValue == 1 ? true : false
        }
        set {
            decimalValue = newValue ? 1 : 0
        }
    }

    var sizeInBits: Int = 0
    
    var sizeLabel: String {
        if sizeInBits >= 8 {
            let byteSize = sizeInBits / 8
            if byteSize > 1 {
                return "\(byteSize) Bytes"
            }
            return "\(byteSize) Byte"
        }
        return "\(sizeInBits) Bits"
    }
    
    // MARK: - Hexadecimal Representation

    var hexString: String {
        "0x\(rawHex)"
    }
    
    var rawHex: String {
        var hexStringLength = 1
        if sizeInBits > 4 {
            hexStringLength = sizeInBits / 4
        }
        let hex = String(decimalValue, radix: 16)
        let spacerZeros = hexStringLength - hex.count
        if spacerZeros <= 0 {
            return hex
        }
        return String(repeating: "0", count: spacerZeros) + hex
    }
    
    var rangeLabel: String {
        "\(range.lowerBound) - \(range.upperBound - 1)"
    }
    
    // MARK: - Binary Representation

    var binary: String {
        let binary = String(decimalValue, radix: 2)
        let paddedBinary = String(repeating: "0", count: 64 - binary.count) + binary

        let idx = paddedBinary.index(paddedBinary.startIndex, offsetBy: (64 - self.sizeInBits))
        return String(paddedBinary[idx..<paddedBinary.endIndex])
    }
    
    init(name: PacketChunkDescription,
         sizeInBits: Int,
         defaultValue: UInt64 = 0,
         editable: Bool = false,
         uiType: ChunkDisplayType = .none,
         definedMax: UInt64? = nil) {
        self.name = name
        self.sizeInBits = sizeInBits
        self.editable = editable
        self.uiType = uiType
        self.decimalValue = defaultValue
        self.definedMax = definedMax
    }
}
