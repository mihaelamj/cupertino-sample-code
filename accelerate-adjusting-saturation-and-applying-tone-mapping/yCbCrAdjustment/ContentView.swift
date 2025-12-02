/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main UI structure.
*/

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var ycbcrAdjustment: YpCbCrAdjustment
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    static func format(_ value: Float) -> String {
        Self.formatter.string(from: value as NSNumber)!
    }
    
    func reset() {
        ycbcrAdjustment.reset()
    }
    
    let font = Font.system(.body, design: .default).monospacedDigit()
    
    var body: some View {
        VStack {
            Image(decorative: ycbcrAdjustment.outputImage, scale: 1)
                .resizable()
                .scaledToFit()
                .padding()
            
            Divider()
            
            Grid {
                GridRow {
                    Text("Saturation")
           
                    Slider(value: self.$ycbcrAdjustment.saturation,
                           in: 0 ... 2)
                    
                    Text("\(Self.format(self.ycbcrAdjustment.saturation))")
                        .font(self.font)
                }
                
                GridRow {
                    Text("Luma Gamma")
                
                    Slider(value: self.$ycbcrAdjustment.lumaGamma,
                           in: 0.5 ... 2.5)
                    
                    Text("\(Self.format(self.ycbcrAdjustment.lumaGamma))")
                        .font(self.font)
                }
            }
            .padding()
        }.toolbar {
            Toggle(isOn: self.$ycbcrAdjustment.useLinear) {
                Text("sRGB → Linear")
                    .font(self.font)
            }
            
            Button(action: self.reset) {
                Text("Reset")
                    .font(self.font)
            }
        }
    }
}
