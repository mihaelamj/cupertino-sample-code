/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The user interface for hue adjustment in the L*a*b* color space app.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var labHueRotate: LabHueRotate
    
    let font = Font.system(.body, design: .default).monospacedDigit()
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    var hueAngle: String {
        let angle = Measurement(value: Double(labHueRotate.hueAngle),
                                unit: UnitAngle.radians).converted(to: UnitAngle.degrees).value
        
        return Self.formatter.string(from: angle as NSNumber)! + "º"
    }
    
    var body: some View {
        
        VSplitView {
            Image(decorative: labHueRotate.outputImage,
                  scale: 1)
            .resizable()
            .aspectRatio(contentMode: .fit)
            
            HStack {
                Slider(value: $labHueRotate.hueAngle,
                       in: -Float.pi ... Float.pi) {
                    Text("Hue Angle")
                        .font(self.font)
                }
                Text("\(hueAngle)")
                    .font(self.font)
            }
            .padding()
        }
    }
}
