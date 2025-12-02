/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom resampling user interface file.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var customResamplingEngine: CustomResamplingEngine
    
    var body: some View {
        VStack {

            Image(decorative: customResamplingEngine.outputImage,
                  scale: 1)
            .resizable()
            .aspectRatio(contentMode: .fit)
            
            Spacer()
            Divider()
            
            Picker("Mode", selection: $customResamplingEngine.mode) {
                ForEach(CustomResamplingEngine.Mode.allCases) { mode in
                    Text(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding()
    }
}

