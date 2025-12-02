/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The user interface file for the ends-in contrast-stretching app.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var contrastStretcher: ContrastStretcher
    
    var body: some View {
        VStack {
            
            Image(decorative: contrastStretcher.outputImage,
                  scale: 1)
            .resizable()
            .aspectRatio(contentMode: .fit)
            
            Spacer()
            Divider()
            
            HStack {
                Slider(
                    value: $contrastStretcher.percentLow,
                    in: 0...100
                ) {
                    Text("Percent Low")
                }
                Text("\(Int(contrastStretcher.percentLow))")
            }
            
            HStack {
                Slider(
                    value: $contrastStretcher.percentHigh,
                    in: 0...100
                ) {
                    Text("Percent High")
                }
                Text("\(Int(contrastStretcher.percentHigh))")
            }
        }
        .padding()
    }
}
