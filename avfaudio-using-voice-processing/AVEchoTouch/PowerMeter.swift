/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Calculates audio powers.
*/

import Foundation
import AVFoundation
import Accelerate

class PowerMeter: AudioLevelProvider {
    private let kMinLevel: Float = 0.000_000_01 // -160 dB

    private struct PowerLevels {
        let average: Float
        let peak: Float
    }

    private var values = [PowerLevels]()
    
    private var meterTableAvarage = MeterTable()
    private var meterTablePeak = MeterTable()

    var levels: AudioLevels {
        if values.isEmpty { return AudioLevels(level: 0.0, peakLevel: 0.0) }
        return AudioLevels(level: meterTableAvarage.valueForPower(values[0].average),
                           peakLevel: meterTablePeak.valueForPower(values[0].peak))
    }
    
    func processSilence() {
        if values.isEmpty { return }
        values = []
    }

    // Calculates the average (rms) and peak level of each channel in the PCM buffer and caches data.
    func process(buffer: AVAudioPCMBuffer) {
        var powerLevels = [PowerLevels]()
        let channelCount = Int(buffer.format.channelCount)
        let length = vDSP_Length(buffer.frameLength)

        if let floatData = buffer.floatChannelData {
            for channel in 0..<channelCount {
                powerLevels.append(calculatePowers(data: floatData[channel], strideFrames: buffer.stride, length: length))
            }
        } else if let int16Data = buffer.int16ChannelData {
            for channel in 0..<channelCount {
                // Convert the data from int16 to float values before calculating the power values.
                var floatChannelData: [Float] = Array(repeating: Float(0.0), count: Int(buffer.frameLength))
                vDSP_vflt16(int16Data[channel], buffer.stride, &floatChannelData, buffer.stride, length)
                var scalar = Float(INT16_MAX)
                vDSP_vsdiv(floatChannelData, buffer.stride, &scalar, &floatChannelData, buffer.stride, length)

                powerLevels.append(calculatePowers(data: floatChannelData, strideFrames: buffer.stride, length: length))
            }
        } else if let int32Data = buffer.int32ChannelData {
            for channel in 0..<channelCount {
                // Convert the data from int32 to float values before calculating the power values.
                var floatChannelData: [Float] = Array(repeating: Float(0.0), count: Int(buffer.frameLength))
                vDSP_vflt32(int32Data[channel], buffer.stride, &floatChannelData, buffer.stride, length)
                var scalar = Float(INT32_MAX)
                vDSP_vsdiv(floatChannelData, buffer.stride, &scalar, &floatChannelData, buffer.stride, length)

                powerLevels.append(calculatePowers(data: floatChannelData, strideFrames: buffer.stride, length: length))
            }
        }
        self.values = powerLevels
    }

    private func calculatePowers(data: UnsafePointer<Float>, strideFrames: Int, length: vDSP_Length) -> PowerLevels {
        var max: Float = 0.0
        vDSP_maxv(data, strideFrames, &max, length)
        if max < kMinLevel {
            max = kMinLevel
        }

        var rms: Float = 0.0
        vDSP_rmsqv(data, strideFrames, &rms, length)
        if rms < kMinLevel {
            rms = kMinLevel
        }

        return PowerLevels(average: 20.0 * log10(rms), peak: 20.0 * log10(max))
    }
}
