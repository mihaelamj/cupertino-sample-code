/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The EnergyKit Error view.
*/

import EnergyKit
import SwiftUI

struct EnergyKitErrorView: View {
    var error: EnergyKitError
    
    var body: some View {
        if error == .permissionDenied {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) { }
        } else {
            HStack {
                icon
                VStack(alignment: .leading) {
                    Button("Close", role: .close) {}
                }
            }
        }
    }
    
    private var icon: Image {
        switch error {
        case .permissionDenied:
            return Image(systemName: "exclamationmark.circle")
        case .locationServicesDenied:
            return Image(systemName: "exclamationmark.circle")
        default:
            return Image(systemName: "exclamationmark.circle")
        }
    }
}
