/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SVD image compression content view.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var imageCompressor: SVDImageCompressor
    
    var body: some View {
        
        VSplitView {
            HStack {
                VStack {
                    Text("Original Image")
                        .font(.title2)
                    Image(decorative: imageCompressor.originalImage,
                          scale: 1)
                        .resizable()
                        .scaledToFit()
                }
                .padding()
                VStack {
                    Text("SVD Compressed Image")
                        .font(.title2)
                    ZStack {
                        Image(decorative: imageCompressor.svdCompressedImage,
                              scale: 1)
                            .resizable()
                            .scaledToFit()
                            .opacity(imageCompressor.busy ? 0.5 : 1)
                            .blur(radius: imageCompressor.busy ? 5 : 0)
                        if imageCompressor.busy {
                            ProgressView()
                        }
                    }
                }
                .padding()
            }
            HStack {
                Picker("k =", selection: $imageCompressor.k) {
                    ForEach(0 ..< 6) {
                        Text("\(SVDImageCompressor.kValues[$0])").tag(SVDImageCompressor.kValues[$0])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(imageCompressor.busy)
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SVDImageCompressor(image: #imageLiteral(resourceName: "Flowers_square.jpeg")))
    }
}
