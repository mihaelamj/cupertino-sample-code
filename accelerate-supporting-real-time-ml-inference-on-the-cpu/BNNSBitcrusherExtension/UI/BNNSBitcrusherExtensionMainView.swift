/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher main view.
*/

import SwiftUI

struct BNNSBitcrusherExtensionMainView: View {
    
    var parameterTree: ObservableAUParameterGroup
    
    var body: some View {

        ParameterSlider(param: parameterTree.global.resolution)
        ParameterSlider(param: parameterTree.global.saturationGain)
        ParameterSlider(param: parameterTree.global.mix)
        
        WaveformDisplay(resolution: parameterTree.global.resolution,
                        saturationGain: parameterTree.global.saturationGain,
                        mix: parameterTree.global.mix)
        .frame(height: 200)
        
    }
}
