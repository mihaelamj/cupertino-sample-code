/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The YUV-to-RGB user interface file.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var converter: YUVtoRGBConverter
    
    var body: some View {
        VStack {
            
            Image(decorative: converter.outputImage,
                  scale: 1)
            .resizable()
            .aspectRatio(contentMode: .fit)
         
            Divider()
            
            Slider(value: $converter.contrast, in: 0.25 ... 4) {
                Text("Contrast")
            }
        }
        .padding()
    }
}
