/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit main view file.
*/


import SwiftUI

struct vDSP_audio_unitExtensionMainView: View {
    var parameterTree: ObservableAUParameterGroup
    
    var body: some View {
        ParameterSlider(param: parameterTree.global.frequency)
        ParameterSlider(param: parameterTree.global.Q)
        ParameterSlider(param: parameterTree.global.dbGain)
        
        BiquadCurveDisplay(frequency: parameterTree.global.frequency,
                           Q: parameterTree.global.Q,
                           dbGain: parameterTree.global.dbGain)
    }
}
