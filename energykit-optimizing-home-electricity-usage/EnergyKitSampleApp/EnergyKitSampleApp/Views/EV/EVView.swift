/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The electric vehicle view.
*/

import SwiftUI

/// The electric vehicle view.
struct EVView: View {
    @Environment(ElectricVehicleController.self) private var model

    @State private var isDetailsPresented = false

    var body: some View {
        HStack {
            Image(systemName: "bolt.car")
                .imageScale(.large)
                .foregroundStyle(.gray)
            VStack(alignment: .leading) {
                Text("My EV")
                    .font(.headline.leading(.tight))
                    .foregroundStyle(.primary)
                Text(model.configuration.properties.vehicleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onTapGesture {
            isDetailsPresented.toggle()
        }
        .sheet(isPresented: $isDetailsPresented) {
            EVDetailsView()
        }
    }
}
