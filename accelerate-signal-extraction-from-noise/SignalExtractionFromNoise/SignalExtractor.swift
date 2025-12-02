/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Signal extractor from noise class.
*/

import Accelerate
import Cocoa
import Combine


class SignalExtractor: ObservableObject {
    
    static let sampleCount = 1024
    
    static let forwardDCTSetup = vDSP.DCT(count: sampleCount,
                                   transformType: vDSP.DCTTransformType.II)!
    
    static let inverseDCTSetup = vDSP.DCT(count: sampleCount,
                                   transformType: vDSP.DCTTransformType.III)!
    
    @Published var displayedWaveform = [Float](repeating: 0,
                                               count: sampleCount)
    
    @Published var threshold = Double(0) {
        didSet {
            displaySignalFromNoise()
        }
    }
    
    @Published var noiseAmount: Double = 0 {
        didSet {
            noisySignal = Self.generateSignal(noiseAmount: noiseAmount,
                                              sampleCount: Self.sampleCount)
            
            displaySignalFromNoise()
        }
    }
    
    @Published var showFrequencyDomain = false {
        didSet {
            displayedWaveform = showFrequencyDomain ? frequencyDomainSignal : timeDomainSignal
        }
    }
    
    var noisySignal: [Float]
    
    var timeDomainSignal = [Float](repeating: 0,
                                   count: sampleCount)
    
    var frequencyDomainSignal = [Float](repeating: 0,
                                        count: sampleCount)
    
    init() {
        noisySignal = Self.generateSignal(noiseAmount: 0,
                                          sampleCount: Self.sampleCount)
        
        displaySignalFromNoise()
    }
    
    func displaySignalFromNoise() {
        Self.extractSignalFromNoise(noisySignal: noisySignal,
                                    threshold: threshold,
                                    timeDomainDestination: &timeDomainSignal,
                                    frequencyDomainDestination: &frequencyDomainSignal)
        
        displayedWaveform = showFrequencyDomain ? frequencyDomainSignal : timeDomainSignal
    }
    
    static func generateSignal(noiseAmount: Double,
                               sampleCount: Int) -> [Float] {
        
        let tau = Float.pi * 2
        
        return (0 ..< sampleCount).map { i in
            let phase = Float(i) / Float(sampleCount) * tau
            
            var signal = cos(phase * 1) * 1.0
                signal += cos(phase * 2) * 0.8
                signal += cos(phase * 4) * 0.4
                signal += cos(phase * 8) * 0.8
                signal += cos(phase * 16) * 1.0
                signal += cos(phase * 32) * 0.8
            
            return signal + .random(in: -1...1) * Float(noiseAmount)
        }
    }
    
    static func extractSignalFromNoise(noisySignal: [Float],
                                       threshold: Double,
                                       timeDomainDestination: inout [Float],
                                       frequencyDomainDestination: inout [Float]) {
        
        forwardDCTSetup.transform(noisySignal,
                                  result: &frequencyDomainDestination)
        
        vDSP.threshold(frequencyDomainDestination,
                       to: Float(threshold),
                       with: .zeroFill,
                       result: &frequencyDomainDestination)
        
        
        inverseDCTSetup.transform(frequencyDomainDestination,
                                  result: &timeDomainDestination)
        
        
        let divisor = Float(Self.sampleCount / 2)
        
        vDSP.divide(timeDomainDestination,
                    divisor,
                    result: &timeDomainDestination)
        
    }
}
