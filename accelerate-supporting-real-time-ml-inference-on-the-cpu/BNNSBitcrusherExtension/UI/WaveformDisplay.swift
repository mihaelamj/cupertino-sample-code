/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher waveform display component.
*/


import SwiftUI
import Accelerate
import Charts

let sampleCount = 1024

struct WaveformDisplay: View {
    
    let sourceTensor: BNNSTensor = {
        let sineWave = [Float](unsafeUninitializedCapacity: sampleCount) {
            buffer, initializedCount in
            
            for i in 0 ..< sampleCount {
                buffer[i] = sin(Float(i) / ( Float(sampleCount) / .pi) * 4)
            }
            
            initializedCount = sampleCount
        }
        
        return BNNSTensor(initializingFrom: sineWave,
                          shape: [sampleCount, 1, 1],
                          stride: [1, 1, 1])
    }()
    
    let resolutionTensor = BNNSTensor.allocateUninitialized(scalarType: Float.self,
                                                            shape: [1, 1, 1],
                                                            stride: [1, 1, 1])
    
    let saturationGainTensor = BNNSTensor.allocateUninitialized(scalarType: Float.self,
                                                                shape: [1, 1, 1],
                                                                stride: [1, 1, 1])
    
    let mixValueTensor = BNNSTensor.allocateUninitialized(scalarType: Float.self,
                                                          shape: [1, 1, 1],
                                                          stride: [1, 1, 1])
    
    let destinationTensor = BNNSTensor.allocateUninitialized(scalarType: Float.self,
                                                             shape: [sampleCount, 1, 1],
                                                             stride: [1, 1, 1])
    
    // Declare BNNSGraph objects.
    let context: BNNSGraph.Context
    
    // Create the indices into the arguments array.
    let dstIndex: Int
    let srcIndex: Int
    let resolutionIndex: Int
    let saturationGainIndex: Int
    let dryWetIndex: Int
    
    @ObservedObject var resolution: ObservableAUParameter
    @ObservedObject var saturationGain: ObservableAUParameter
    @ObservedObject var mix: ObservableAUParameter
    
    init(resolution: ObservableAUParameter,
         saturationGain: ObservableAUParameter,
         mix: ObservableAUParameter) {
        
        self.resolution = resolution
        self.saturationGain = saturationGain
        self.mix = mix
        
        context = try! BNNSGraph.makeContext {
            builder in
            
            var source = builder.argument(name: "source",
                                          dataType: Float.self,
                                          shape: [sampleCount, 1, 1])
            
            let resolution = builder.argument(name: "resolution",
                                              dataType: Float.self,
                                              shape: [1, 1, 1])
            
            let saturationGain = builder.argument(name: "saturationGain",
                                                  dataType: Float.self,
                                                  shape: [1, 1, 1])
            
            var dryWet = builder.argument(name: "dryWet",
                                          dataType: Float.self,
                                          shape: [1, 1, 1])
            
            // Saturation
            var destination = source * saturationGain
            destination = destination.tanh()
            
            // Quantization
            
            destination = destination * resolution
            destination = destination.round()
            destination = destination / resolution
            
            // Mix
            destination = destination * dryWet
            dryWet = Float(1) - dryWet
            source = source * dryWet
            
            destination = destination + source
            
            return [destination]
        }
        
        // Calculate indices into the arguments array.
        dstIndex = 0
        srcIndex = context.argumentPosition(argument: "source")
        resolutionIndex = context.argumentPosition(argument: "resolution")
        saturationGainIndex = context.argumentPosition(argument: "saturationGain")
        dryWetIndex = context.argumentPosition(argument: "dryWet")
        
        updateChartData()
    }
    
    func updateChartData() {
        
        resolutionTensor.data?.initializeMemory(as: Float.self, to: resolution.value)
        saturationGainTensor.data?.initializeMemory(as: Float.self, to: saturationGain.value)
        mixValueTensor.data?.initializeMemory(as: Float.self, to: mix.value)
        
        // Specify output and input arguments.
        var arguments = [(destinationTensor, dstIndex),
                         (sourceTensor, srcIndex),
                         (resolutionTensor, resolutionIndex),
                         (saturationGainTensor, saturationGainIndex),
                         (mixValueTensor, dryWetIndex)]
            .sorted { a, b in
                a.1 < b.1
            }
            .map {
                return $0.0
            }
        
        // Run the function.
        try! context.executeFunction(arguments: &arguments)
    }
    
    func destinationValues() -> EnumeratedSequence<UnsafeMutableBufferPointer<Float>> {
        
        let baseAddress = destinationTensor.data?.assumingMemoryBound(to: Float.self)
        return UnsafeMutableBufferPointer<Float>(start: baseAddress,
                                                 count: sampleCount).enumerated()
    }
    
    var body: some View {
        
        Chart {
            ForEach(Array(destinationValues()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.linear)
            }
        }
        .onDisappear {
            sourceTensor.data?.deallocate()
            resolutionTensor.data?.deallocate()
            saturationGainTensor.data?.deallocate()
            mixValueTensor.data?.deallocate()
            destinationTensor.data?.deallocate()
        }
        .onChange(of: resolution.value, initial: true) { _, _ in
            updateChartData()
        }
        .onChange(of: saturationGain.value, initial: true) { _, _ in
            updateChartData()
        }
        .onChange(of: mix.value, initial: true) { _, _ in
            updateChartData()
        }
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .chartYScale(domain: -1.2 ... 1.2)
        .chartXScale(domain: 0 ... sampleCount)
        .padding()
    }
    
}
