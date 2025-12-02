/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The button to set rest duration at a rest stop.
*/

import SwiftUI

struct RestStopLocationButton: View {
    @Environment(AppModel.self) var appModel

    let location: RestStopLocation

    @State var presentTimePicker: Bool = false

    var body: some View {
        Button {
            presentTimePicker.toggle()
        } label: {
            VStack {
                Text("\(appModel.getRestDuration(for: location)) min")
                    .font(.headline)
                Text(location.restStopDirection.rawValue)
                    .font(.caption.smallCaps())
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonBorderShape(.capsule)
        .popover(isPresented: $presentTimePicker, arrowEdge: .bottom) {
            Picker("", selection: Binding( get: {
                appModel.getRestDuration(for: location)
            }, set: {
                appModel.setRestDuration($0, for: location)
            })) {
                Text(0.description + " min")
                    .tag(0)
                Text(15.description + " min")
                    .tag(15)
                Text(30.description + " min")
                    .tag(30)
                Text(60.description + " min")
                    .tag(60)
            }
            .pickerStyle(.wheel)
            .frame(width: 200, height: 150)
        }
    }
}

#Preview(traits: .modifier(HikerComponentAppModelData())) {
    RestStopLocationButton(
        location: RestStopLocation(restStopDirection: .base, trailPercentage: 0.2864)
    )
    .frame(width: 250)
    .padding()
    .glassBackgroundEffect()
}
