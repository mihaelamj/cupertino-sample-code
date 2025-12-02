/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The image UI file.
*/

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var imageDitherEngine: ImageDitherEngine
    
    var body: some View {
        VStack {
      
            Image(decorative: imageDitherEngine.outputImage,
                  scale: 1)
            .resizable()
            .aspectRatio(contentMode: .fit)
            
            Picker("Mode", selection: $imageDitherEngine.ditheringType) {
                ForEach(ImageDitherEngine.DitheringType.allCases, id: \.self) { option in
                    Text(option.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
}
