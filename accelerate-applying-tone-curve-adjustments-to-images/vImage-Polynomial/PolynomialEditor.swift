/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The polynomial editor view.
*/

import SwiftUI
import Accelerate

struct PolynomialEditor: View {
    var title: String
    var color: Color
    @Binding var values: [Double]
    @Binding var coefficients: [Float]
    @State private var selectedIndex = -1

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.title2)

                Spacer()

                Button("Invert", action: invertValues)
                Button("Zero", action: zeroValues)
                Button("Reset", action: resetValues)
            }

            GeometryReader { geometry in
                color
                    .opacity(0.1)
                    .cornerRadius(8)
                Path { path in
                    PolynomialEditor.updatePath(path: &path,
                               size: geometry.size,
                               coefficients: coefficients)
                }
                .stroke(color, lineWidth: 2)

                ForEach(0 ..< 5) { index in
                    Circle()
                        .fill(selectedIndex == index ? .white : color)
                        .frame(width: 15, height: 15)
                        .position(
                            x: CGFloat(index) *
                                (geometry.size.width / CGFloat(PolynomialTransformer.count - 1)),
                            y: geometry.size.height - (geometry.size.height / 1) *
                                CGFloat(values[index]))
                        .gesture(
                            DragGesture(minimumDistance: geometry.size.height / 255,
                                        coordinateSpace: .local)
                                .onChanged { value in
                                    selectedIndex = index
                                    let position = 1 - (value.location.y / geometry.size.height)
                                    values[index] = Double(min(1, max(0, position)) * 1)
                                }
                                .onEnded { _ in
                                    selectedIndex = -1
                                }
                        )
                }
            }
        }
    }

    /// Resets the values.
    func resetValues() {
        vDSP.formRamp(in: 0 ... 1,
                      result: &values)
    }
    
    /// Zeros the values.
    func zeroValues() {
        vDSP.fill(&values, with: 0.0)
    }
    
    /// Inverts the values.
    func invertValues() {
        values = values.map { 1 - $0 }
    }

    /// The 0...1 ramp that `evaluatePolynomial` uses as variables.
    static let ramp = vDSP.ramp(withInitialValue: Float(0),
                                increment: Float(1) / 256,
                                count: 256)
    
    /// Updates the specified path with a smooth curve that an interpolating polynomial generates from the
    /// specified coefficients.
    static func updatePath(path: inout Path,
                           size: CGSize,
                           coefficients: [Float]) {
        
        let polynomialResult = [Float](unsafeUninitializedCapacity: ramp.count) {
            buffer, initializedCount in
            
            vDSP.evaluatePolynomial(usingCoefficients: coefficients.reversed(),
                                    withVariables: ramp,
                                    result: &buffer)
            
            vDSP.clip(buffer,
                      to: 0 ... 1,
                      result: &buffer)
            
            initializedCount = ramp.count
        }

        let cgPath = CGMutablePath()
        let hScale = size.width / 256
        let points: [CGPoint] = polynomialResult.enumerated().map {
            CGPoint(x: CGFloat($0.offset) * hScale,
                    y: size.height - (size.height * CGFloat($0.element) ))
        }
  
        cgPath.addLines(between: points)
        
        path = Path(cgPath)
    }
}
