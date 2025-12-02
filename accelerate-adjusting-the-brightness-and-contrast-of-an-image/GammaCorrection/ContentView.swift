/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Gamma Correction app content view file.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var gammaCorrectionEngine: GammaCorrectionEngine
    
    var body: some View {
        VStack {
            
            Image(decorative: gammaCorrectionEngine.outputImage,
                  scale: 1)
            .resizable()
            .aspectRatio(contentMode: .fit)
            
            Spacer()
            
            Divider()
            Picker("Choose gamma", selection: $gammaCorrectionEngine.responseCurvePreset) {
                ForEach(GammaCorrectionEngine.presets) { preset in
                    Text(preset.id)
                        .tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding()
    }
}
