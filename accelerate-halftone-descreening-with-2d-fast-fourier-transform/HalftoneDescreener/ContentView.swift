/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
FFT halftone descreener content view.
*/

import SwiftUI

struct ContentView: View {
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        return formatter
    }()
    
    @EnvironmentObject var halftoneDescreener: HalftoneDescreener
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Original Image")
                        .font(.title2)
                    Image(decorative: halftoneDescreener.sourceImage,
                          scale: 1)
                    .resizable()
                    .scaledToFit()
                }
                .padding()
                
                VStack {
                    Text("Descreened Image")
                        .font(.title2)
                    Image(decorative: halftoneDescreener.descreenedImage,
                          scale: 1)
                    .resizable()
                    .scaledToFit()
                }
                .padding()
            }
            
            HStack {
                Picker("Threshold", selection: $halftoneDescreener.threshold) {
                    ForEach(0 ..< 5) {
                        Text("\(formatter.string(for: HalftoneDescreener.thresholds[$0])!)").tag(HalftoneDescreener.thresholds[$0])
                    }
                }
                .labelsHidden()
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

