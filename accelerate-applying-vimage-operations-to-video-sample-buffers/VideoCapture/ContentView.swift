/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The YUV-to-RGB user-interface file.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var videoCapture: VideoCapture
    
    var body: some View {
        VStack(alignment: .leading) {
    
            Text("\(videoCapture.info)")
                .font(.title2)
            
            ZStack {
                Image(decorative: videoCapture.outputImage,
                      scale: 1)
                .resizable()
                .aspectRatio(contentMode: .fit)
                
                ProgressView().opacity(videoCapture.isRunning ? 0 : 1)
            }
        }
        .padding()
    }
}
