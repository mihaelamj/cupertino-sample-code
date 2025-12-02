/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The color-to-grayscale conversion user interface.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var grayscaleConverter: GrayscaleConverter
    
    @State private var showDistinctColorCounts = false
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 4
        return formatter
    }()
    
    var body: some View {
        VStack {
            
            VSplitView {
                
                VStack {
                    Text("Original image")
                        .font(.title)
                    Image(decorative: GrayscaleConverter.sourceImage,
                          scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                }
                .padding()
                
                HStack {
                    VStack {
                        Text("8-bit grayscale")
                            .font(.title)
                        Image(decorative: grayscaleConverter.outputImage8Bit,
                              scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    }
                    
                    VStack {
                        Text("32-bit grayscale")
                            .font(.title)
                        Image(decorative: grayscaleConverter.outputImage32Bit,
                              scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    }
                }
                .padding()
            }
            .padding()
            
            Divider()
                .padding()
            
            HStack {
                VStack {
                    Text("Red: \(Self.formatter.string(from: grayscaleConverter.normalizedRedCoefficient as NSNumber)!)")
                        .monospacedDigit()
                    Slider(value: $grayscaleConverter.redCoefficient,
                           in: .ulpOfOne ... 1)
                }
                
                VStack {
                    Text("Green: \(Self.formatter.string(from: grayscaleConverter.normalizedGreenCoefficient as NSNumber)!)")
                        .monospacedDigit()
                    Slider(value: $grayscaleConverter.greenCoefficient,
                           in: .ulpOfOne ... 1)
                }
                
                VStack {
                    Text("Blue: \(Self.formatter.string(from: grayscaleConverter.normalizedBlueCoefficient as NSNumber)!)")
                        .monospacedDigit()
                    Slider(value: $grayscaleConverter.blueCoefficient,
                           in: .ulpOfOne ... 1)
                }
            }
            .padding()
        }
        .toolbar {
            
            Button("Show distinct color counts") {
                showDistinctColorCounts = true
            }
            .alert("""
Distinct color counts

8-bit: \(showDistinctColorCounts ? grayscaleConverter.distinctColorCount8 : 0)
32-bit: \(showDistinctColorCounts ? grayscaleConverter.distinctColorCountF : 0)
""",
                   isPresented: $showDistinctColorCounts) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}
