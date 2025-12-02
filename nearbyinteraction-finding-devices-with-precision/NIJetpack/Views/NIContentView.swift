/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A stub view for the app.
*/

import SwiftUI
import NearbyInteraction

enum FindingMode {
    case exhibit
    case visitor
}

struct NIContentView: View {
    @ViewBuilder
    var body: some View {
        // Check whether this device supports precise distance measurement.
        if !NISession.deviceCapabilities.supportsPreciseDistanceMeasurement {
            NIUnsupportedDeviceView()
        } else {
            NavigationView {
                VStack(spacing: 50) {
                    NavigationLink(destination: NICameraAssistanceView(mode: .exhibit)) {
                        Text("\(Image(systemName: "paintbrush")) Go to next Exhibit.")
                        .padding()
                        .font(.title2)
                        .cornerRadius(10)
                    }
                    if #available(iOS 17.0, watchOS 10.0, *), NISession.deviceCapabilities.supportsExtendedDistanceMeasurement {
                        NavigationLink(destination: NICameraAssistanceView(mode: .visitor)) {
                            Text("\(Image(systemName: "person.2")) Discuss jetpacks with another visitor.")
                            .padding()
                            .font(.title2)
                            .cornerRadius(10)
                        }
                    }
                }
                .navigationTitle("Jetpack Museum")
            }
        }
    }
}

struct NIContentView_Previews: PreviewProvider {
    static var previews: some View {
        NIContentView()
    }
}
