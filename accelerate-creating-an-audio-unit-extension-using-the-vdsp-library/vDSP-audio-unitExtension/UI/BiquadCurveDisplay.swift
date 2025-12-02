/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit magnitude-response chart file.
*/

import SwiftUI
import Charts
import Accelerate

struct BiquadCurveDisplay: View {

    static let sampleCount = 512
    
    static let magnitudeResponseCalculator = MagnitudeResponseCalculator(sampleCount: sampleCount)
    
    @ObservedObject var frequency: ObservableAUParameter
    @ObservedObject var Q: ObservableAUParameter
    @ObservedObject var dbGain: ObservableAUParameter
    
    @State private var magnitudeResponseValues = [Double](repeating: 1, count: sampleCount)

    func makeAxisLabel(_ x: Float) -> String {
        
        var f = x / Float(BiquadCurveDisplay.sampleCount)
        f *= frequency.max
        f = f.rounded(.up)
        return "\(Int(f)) Hz"
    }
    
    var body: some View {
        
        VStack {
            
            Chart {
                ForEach(Array(magnitudeResponseValues.enumerated()), id: \.offset) { index, value in
                    AreaMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(.blue.opacity(0.2))
                    .interpolationMethod(.catmullRom)
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(.gray.opacity(0.2))
                    .clipShape(.rect(cornerRadius: 20))
                
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(preset: .aligned, values: [0.5, 1, 2.025, 4.075, 8.175, 16.36,
                                                     32, 64, 128, 256, 512]) {value in
                    if let x = value.as(Float.self) {
                        AxisValueLabel {
                            Text("\(makeAxisLabel(x))")
                        }
                    }
                }
            }
            .chartYScale(domain: -50...50)
            .chartXScale(domain: 0.5 ... Double(Self.sampleCount), type: .symmetricLog)
            .padding()
        }
        .padding()
        .onChange(of: frequency.value, initial: true) { _, _ in
            magnitudeResponseValues = BiquadCurveDisplay.calculateMagnitudeResponseValues(
                frequency: Double(frequency.value),
                Q: Double(Q.value),
                dbGain: Double(dbGain.value))
        }
        .onChange(of: Q.value, initial: true) { _, _ in
            magnitudeResponseValues = BiquadCurveDisplay.calculateMagnitudeResponseValues(
                frequency: Double(frequency.value),
                Q: Double(Q.value),
                dbGain: Double(dbGain.value))
        }
        .onChange(of: dbGain.value, initial: true) { _, _ in
            magnitudeResponseValues = BiquadCurveDisplay.calculateMagnitudeResponseValues(
                frequency: Double(frequency.value),
                Q: Double(Q.value),
                dbGain: Double(dbGain.value))
        }
    }

    static func calculateMagnitudeResponseValues(frequency: Double,
                                                 Q: Double,
                                                 dbGain: Double) -> [Double] {
        
        let coeffs = biquadCoefficientsFor(sampleRate: 44_100,
                                           frequency: frequency,
                                           Q: Q,
                                           dbGain: dbGain)
        
        let magnitude = magnitudeResponseCalculator.response(for: coeffs)
        
        return magnitude
    }
}

// The `MagnitudeResponseCalculator` is a structure that calculates the
// magnitude response of a set of biquadratic coefficients.
struct MagnitudeResponseCalculator {
    
    let sampleCount: Int
    
    private let reals: [Double]
    private let realsSquared: [Double]
    
    private let imaginaries: [Double]
    private let imaginariesSquared: [Double]
    
    private let realsSquaredImaginariesSquaredDiff: [Double]
    private let realsImaginariesProduct: [Double]
    
    // The `MagnitudeResponseCalculator.init(sampleCount:)` initializer function
    // returns a new magnitude response calculator.
    init(sampleCount: Int) {
        self.sampleCount = sampleCount
        
        let ramp = vDSP.ramp(in: Double() ... 1.0,
                         count: sampleCount)
   
        reals = vForce.cosPi(ramp)
        realsSquared = vDSP.multiply(reals, reals)
        
        imaginaries = vForce.sinPi(ramp)
        imaginariesSquared = vDSP.multiply(imaginaries, imaginaries)
        
        realsSquaredImaginariesSquaredDiff = vDSP.subtract(realsSquared, imaginariesSquared)
        realsImaginariesProduct = vDSP.multiply(reals, imaginaries)
    }
    
    // The following function is a vectorized version of the `magnitudeForFrequency`
    // function from https://developer.apple.com/documentation/audiotoolbox/audio_unit_v3_plug-ins/creating_custom_audio_effects.
    // The function returns the magnitude response of a biquadratic filter for
    // a set of coefficients.
    func response(for coefficients: [Double]) -> [Double] {
        
        let b0 = coefficients[0]
        let b1 = coefficients[1]
        let b2 = coefficients[2]
        let a1 = coefficients[3]
        let a2 = coefficients[4]
        
        // Calculate the zeros response.
        var numeratorReal = vDSP.add(multiplication: (realsSquaredImaginariesSquaredDiff, b0),
                                     multiplication: (reals, b1))
        numeratorReal = vDSP.add(b2, numeratorReal)
        
        let numeratorImaginary = vDSP.add(multiplication: (realsImaginariesProduct, 2 * b0),
                                          multiplication: (imaginaries, b1))
        
        let numeratorMagnitude = vDSP.hypot(numeratorReal, numeratorImaginary)
        
        // Calculate the poles response.
        var denominatorReal = vDSP.add(multiplication: (reals, a1),
                                       realsSquaredImaginariesSquaredDiff)
        denominatorReal = vDSP.add(a2, denominatorReal)
        
        let denominatorImaginary = vDSP.add(multiplication: (realsImaginariesProduct, 2),
                                            multiplication: (imaginaries, a1))
        
        let denominatorMagnitude = vDSP.hypot(denominatorReal, denominatorImaginary)
        
        // Calculate the total response.
        var response = vDSP.divide(numeratorMagnitude, denominatorMagnitude)
        
        vDSP.convert(amplitude: response,
                     toDecibels: &response,
                     zeroReference: 1)
    
        return response
    }
}

@inlinable
public func biquadCoefficientsFor(sampleRate: Double,
                                  frequency: Double,
                                  Q: Double,
                                  dbGain: Double) -> [Double] {
 
    let omega = 2.0 * .pi * frequency / sampleRate
    let sinOmega = sin(omega)
    let alpha = sinOmega / ((2 * Q) + .ulpOfOne.squareRoot())
    let cosOmega = cos(omega)
    
    let A = pow(10.0, dbGain / 40)
 
    let b0 = 1 + alpha * A
    let b1 = -2 * cosOmega
    let b2 = 1 - alpha * A
    let a0 = 1 + alpha / A
    let a1 = -2 * cosOmega
    let a2 = 1 - alpha / A
    
    let coeffs = [b0 / a0,
                  b1 / a0,
                  b2 / a0,
                  a1 / a0,
                  a2 / a0]
    
    return coeffs
}
