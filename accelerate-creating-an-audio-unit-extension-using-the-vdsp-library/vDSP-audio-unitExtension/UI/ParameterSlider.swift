/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit parameter slider control file.
*/

import SwiftUI

/// A SwiftUI `Slider` container, which is bound to an `ObservableAUParameter`.
///
/// This view wraps a SwiftUI `Slider`, and provides it relevant data from the parameter, like the minimum and maximum values.
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
