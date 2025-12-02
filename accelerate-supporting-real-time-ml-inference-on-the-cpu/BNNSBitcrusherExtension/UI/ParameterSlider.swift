/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher parameter slider control.
*/

import SwiftUI

/// A SwiftUI slider container with a binding to an `ObservableAUParameter`.
///
/// This view wraps a SwiftUI slider and provides it relevant data from the parameter, such as the minimum and maximum values.
struct ParameterSlider: View {
    @ObservedObject var param: ObservableAUParameter
    
    var specifier: String {
        switch param.unit {
        case .midiNoteNumber:
            return "%.0f"
        default:
            return "%.2f"
        }
    }
    
    var body: some View {
        VStack {
            Slider(
                value: $param.value,
                in: param.min...param.max,
                onEditingChanged: param.onEditingChanged,
                minimumValueLabel: Text("\(param.min, specifier: specifier)"),
                maximumValueLabel: Text("\(param.max, specifier: specifier)")
            ) {
                EmptyView()
            }
            Text("\(param.displayName): \(param.value, specifier: specifier)")
        }
        .padding()
    }
}
