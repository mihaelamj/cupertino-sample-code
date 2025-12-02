/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The trim transparent pixels app user-interface file.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var imageProvider: ImageProvider
    
    var body: some View {
        HStack {
            Image(decorative: imageProvider.originalImage, scale: 1)
                .resizable()
            
            Divider()
            
            Image(decorative: imageProvider.alphaImage, scale: 1)
                .resizable()
            
            Divider()
            
            Image(decorative: imageProvider.outputImage, scale: 1)
                .resizable()
                .background(.gray)
        }
            .padding()
    }
}
