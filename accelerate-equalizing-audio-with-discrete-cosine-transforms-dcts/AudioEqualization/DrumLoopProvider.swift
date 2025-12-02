/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that provides a signal that represents a drum loop.
*/

import Accelerate
import Combine

/// A class that provides a drum loop and exposes properties to apply audio equalization.
class DrumLoopProvider: ObservableObject {
    
    /// An enumeration that specifies the drum loop provider's mode.
    enum Mode: String, CaseIterable, Identifiable {
        
        /// The equalization allows frequencies between `startFrequency` and `endFrequency`.
        case bandPass
        
        /// The equalization eliminates frequencies between `startFrequency` and `endFrequency`.
        case bandStop
        
        var id: Self { self }
    }
    
    /// The drum loop provider's mode.
    @Published var mode = Mode.bandPass {
        didSet {
            updateEnvelope()
        }
    }
    
    /// The envelope start frequency.
    @Published var startFrequency = 100.0 {
        didSet {
            if startFrequency + 5 > endFrequency {
                endFrequency = startFrequency + 5
            }
            
            updateEnvelope()
        }
    }
    
    /// The envelope end frequency.
    @Published var endFrequency = 924.0 {
        didSet {
            if endFrequency - 5 < startFrequency {
                startFrequency = endFrequency - 5
            }
            
            updateEnvelope()
        }
    }
    
    /// An array of floating-point values that the audio-equalization operation multiplies by the frequency-domain
    /// representation of the drum loop.
    @Published var envelope: [Float]!
    
    /// An array of floating-point values that contains the temporally smoothed frequency-domain representation
    /// of the drum loop.
    @Published var displayedEqualizedFrequencyDomainSignal = [Float](repeating: 0, count: sampleCount)
    
    /// An array of floating-point values that contains the equalized frequency-domain representation of the
    /// drum loop.
    var equalizedFrequencyDomainSignal: [Float] = [Float](repeating: 0, count: sampleCount)
    
    /// An array of floating-point values that contains the equalized time-domain representation of the
    /// drum loop.
    var equalizedTimeDomainSignal: [Float] = [Float](repeating: 0, count: sampleCount)
    
    func updateEnvelope() {
        let start = Float(startFrequency)
        let end = Float(endFrequency)
        
        let indices = [0, start - 2, start, end, end + 2, 1024]
        let magnitudes: [Float]
        
        switch mode {
            case .bandPass:
                magnitudes = [0, 0, 1, 1, 0, 0]
            case .bandStop:
                magnitudes = [1, 1, 0, 0, 1, 1]
        }
        
        envelope = [Float](unsafeUninitializedCapacity: DrumLoopProvider.sampleCount) {
            buffer, initializedCount in
            
            vDSP.linearInterpolate(values: magnitudes,
                                   atIndices: indices,
                                   result: &buffer)
            
            initializedCount = DrumLoopProvider.sampleCount
        }
    }
    
    init() {
        updateEnvelope()
    }
    
    static let sampleCount = 1024
    
    static let forwardDCT = vDSP.DCT(count: sampleCount,
                                     transformType: .II)!
    
    static let inverseDCT = vDSP.DCT(count: sampleCount,
                                     transformType: .III)!
    
    /// The current page of `sampleCount` elements in `samples`.
    private var pageNumber = 0
    
    /// An array that contains the samples for the entire audio resource.
    private var samples = [Float]()
    
    /// The sample rate of the drum loop sample.
    public var sampleRate = Int32(0)
    
    /// Loads the audio sample data and populates the `samples` array and `sampleRate` value.
    func loadAudioSamples() async throws {
        
        guard let samples = try await AudioUtilities.getAudioSamples(
            forResource: "Rhythm",
            withExtension: "aif") else {
            fatalError("Unable to parse the audio resource.")
        }
        
        self.samples = samples.data
        self.sampleRate = samples.naturalTimeScale
    }
    
    /// Performs a forward DCT to the values in source, multiplies the frequency-domain data by the
    /// `dctMultiplier` values, and performs an inverse DCT on the product.
    static func apply(dctMultiplier: [Float],
                      source: [Float],
                      frequencyDomainDestination: inout [Float],
                      timeDomainDestination: inout [Float]) {
        
        // Perform forward DCT.
        forwardDCT.transform(source,
                             result: &frequencyDomainDestination)
        // Multiply frequency-domain data by `dctMultiplier`.
        vDSP.multiply(dctMultiplier,
                      frequencyDomainDestination,
                      result: &frequencyDomainDestination)
        
        // Perform inverse DCT.
        inverseDCT.transform(frequencyDomainDestination,
                             result: &timeDomainDestination)
        
        // In-place scale inverse DCT result by n / 2.
        // Output samples are now in range -1...+1.
        vDSP.divide(timeDomainDestination,
                    Float(DrumLoopProvider.sampleCount / 2),
                    result: &timeDomainDestination)
    }
}

// MARK: SignalProvider Extension

extension DrumLoopProvider: SignalProvider {
    
    /// Returns a page that contains `sampleCount` samples from the `samples` array.
    func getSignal() -> [Float] {
        let start = pageNumber * Self.sampleCount
        let end = (pageNumber + 1) * Self.sampleCount
        
        let page = Array(samples[start ..< end])
        
        pageNumber += 1
        
        if (pageNumber + 1) * Self.sampleCount >= samples.count {
            pageNumber = 0
        }
        
        DrumLoopProvider.apply(dctMultiplier: envelope,
                               source: page,
                               frequencyDomainDestination: &equalizedFrequencyDomainSignal,
                               timeDomainDestination: &equalizedTimeDomainSignal)
        
        
        let interpolationConstant: Float = 0.5
        DispatchQueue.main.async { [self] in
            // Create a smoothly animated version of the frequency-domain signal
            // that the sample app displays in the user interface.
            vDSP.linearInterpolate(equalizedFrequencyDomainSignal,
                                   displayedEqualizedFrequencyDomainSignal,
                                   using: interpolationConstant,
                                   result: &displayedEqualizedFrequencyDomainSignal)
            
        }
        
        return equalizedTimeDomainSignal
    }
}
