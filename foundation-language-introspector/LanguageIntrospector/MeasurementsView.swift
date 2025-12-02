/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for measurements.
*/

import SwiftUI

struct MeasurementsView: View {
    @State private var model = MeasurementsModel()
    
    var body: some View {
        VStack {
            HeaderImage(name: "speedometer")
            
            VStack {
                Group {
                    Text(model.localizedTemperature)
                    Text(model.localizedSpeed)
                    Text(model.localizedArea)
                }
                .font(.title2)
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                Toggle(isOn: $model.providedUnit, label: {
                    Text("दी गई इकाई", comment: "Provided Unit")
                })
                Toggle(isOn: $model.naturalScale, label: {
                    Text("प्राकृतिक पैमाना", comment: "Natural Scale")
                })
                Toggle(isOn: $model.temperatureWithoutUnit, label: {
                    Text("बग़ैर इकाई (सिर्फ़ तापमान पर लागू)", comment: "Temperature Without Unit")
                })
                
                Picker("", selection: $model.selectedUnitStyle) {
                    Text(verbatim: "•").tag(MeasurementFormatter.UnitStyle.short)
                    Text(verbatim: "••").tag(MeasurementFormatter.UnitStyle.medium)
                    Text(verbatim: "•••").tag(MeasurementFormatter.UnitStyle.long)
                }
                .pickerStyle(.segmented)
            }
            .opaqueBackground()
            Spacer()
        }
    }
}
