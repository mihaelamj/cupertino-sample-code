/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MorphologyTransformer user interface file.
*/

import SwiftUI

struct ContentView: View {
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    static func format(_ value: Double) -> String {
        Self.formatter.string(from: value as NSNumber)!
    }
    
    let monospacedFont = Font.system(.body, design: .default).monospacedDigit()
    
    @EnvironmentObject var morphologyTransformer: MorphologyTransformer
    
    var body: some View {
        VStack {
            
            Image(decorative: morphologyTransformer.outputImage,
                  scale: 1)
            .resizable()
            .aspectRatio(contentMode: .fit)
            
            Divider()
            
            HStack {
                Grid {
                    GridRow {
                        Text("Diaphragm Blade Count")
                        
                        Slider(value: $morphologyTransformer.diaphragmBladeCount,
                               in: 3 ... 8,
                               step: 1)
                        
                        Text("\(Self.format(morphologyTransformer.diaphragmBladeCount))")
                            .font(self.monospacedFont)
                    }
                    
                    GridRow {
                        Text("Bokeh Radius")
                        
                        Slider(value: $morphologyTransformer.bokehRadius,
                               in: 5 ... 25,
                               step: 1)
                        
                        Text("\(Self.format(morphologyTransformer.bokehRadius))")
                            .font(self.monospacedFont)
                    }
                    
                    GridRow {
                        Text("Angle")
                        
                        Slider(value: $morphologyTransformer.angle.degrees,
                               in: 0 ... 360,
                               step: 15)
                        
                        Text("\(Self.format(morphologyTransformer.angle.degrees))°")
                            .font(self.monospacedFont)
                    }
                }
                
                ZStack {
                    Rectangle()
                        .fill(.white)
                        .frame(width: 75, height: 75, alignment: .center)
                    
                    Image(decorative: morphologyTransformer.structuringElementImage, scale: 1)
                        .frame(width: 75, height: 75)
                        .aspectRatio(contentMode: .fit)
                }
            }
            
        }
        .padding()
    }
}
