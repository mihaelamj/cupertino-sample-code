/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The content view for the DCT audio equalization app.
*/

import SwiftUI
import Accelerate

struct ContentView: View {
    
    @EnvironmentObject var drumLoopProvider: DrumLoopProvider
    
    var body: some View {
        VStack {
            
            GeometryReader { geometry in
                Path { path in
                    Self.updatePath(path: &path,
                                    size: geometry.size,
                                    signal: drumLoopProvider.displayedEqualizedFrequencyDomainSignal,
                                    minimum: -5,
                                    maximum: 5)
                }
                .stroke(.blue,
                        lineWidth: 3)
                .clipped()
                .background(.white)
                
                Path { path in
                    Self.updatePath(path: &path,
                                    size: geometry.size,
                                    signal: drumLoopProvider.envelope,
                                    minimum: -0.5,
                                    maximum: 1.5)
                }
                .stroke(.red,
                        style: StrokeStyle(lineWidth: 2,
                                           dash: [2]))
                .clipped()
            }
            
            HStack {
                
                Slider(
                    value: $drumLoopProvider.startFrequency,
                    in: 0...1024
                )
                
                Slider(
                    value: $drumLoopProvider.endFrequency,
                    in: 0...1024
                )
                
                Spacer(minLength: 100)
                
                Picker("Mode", selection: $drumLoopProvider.mode) {
                    ForEach(DrumLoopProvider.Mode.allCases) { mode in
                        Text(mode.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
        }
        .padding()
    }
    
    static func updatePath(path: inout Path,
                           size: CGSize,
                           signal: [Float],
                           minimum: Float,
                           maximum: Float) {
        
        let count = signal.count
        
        let scale = 1 / (maximum - minimum)
        let minusMin = [Float](repeating: -minimum, count: count)
        let scaled = vDSP.multiply(addition: (signal, minusMin), scale)
        
        let xScale = size.width / CGFloat(count)
        let points = scaled.enumerated().map {
            return CGPoint(x: xScale * CGFloat($0.offset),
                           y: size.height * CGFloat(1.0 - $0.element))
        }
        
        let cgPath = CGMutablePath()
        cgPath.addLines(between: points)
        
        path = Path(cgPath)
    }
}
