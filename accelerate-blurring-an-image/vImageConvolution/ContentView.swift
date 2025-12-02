/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The image convolution user interface.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var imageConvolver: ImageConvolver
    
    var body: some View {
        VStack {
            Image(decorative: imageConvolver.outputImage,
                  scale: 1)
            .resizable()
            .aspectRatio(contentMode: .fit)
            
            Picker("Mode", selection: $imageConvolver.mode) {
                ForEach(ImageConvolver.Mode.allCases, id: \.self) { option in
                           Text(option.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
}

