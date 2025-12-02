/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The histogram specification user interface file.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var histogramSpecifier: HistogramSpecifier

    var body: some View {
        HSplitView {
            
            HStack {
                VStack {
                    Text("Histogram Source")
                        .font(.title)
                    List(HistogramSpecifier.images,
                         id: \.self,
                         selection: $histogramSpecifier.histogramSource) { image in
                        HStack {
                            Spacer()
                            Image(decorative: image.cgImage,
                                  scale: 8)
                            .opacity(image == histogramSpecifier.histogramSource ? 1 : 0.25)
                            Spacer()
                        }
                    }
                }
                .frame(width: 200)
                .padding()
                
                VStack {
                    Text("Image Source")
                        .font(.title)
                    List(HistogramSpecifier.images,
                         id: \.self,
                         selection: $histogramSpecifier.imageSource) { image in
                        HStack {
                            Spacer()
                            Image(decorative: image.cgImage,
                                  scale: 8)
                            .opacity(image == histogramSpecifier.imageSource ? 1 : 0.25)
                            Spacer()
                        }
                    }
                }
                .frame(width: 200)
                .padding()
            }
            
            Image(decorative: histogramSpecifier.outputImage,
                  scale: 1)
            .resizable()
            .scaledToFit()
            .padding()
        }
        .padding()
    }
}
