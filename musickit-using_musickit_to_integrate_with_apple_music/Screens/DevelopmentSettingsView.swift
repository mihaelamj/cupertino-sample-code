/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Controls for functionality that the app might hide temporarily.
*/

import SwiftUI

/// DevelopmentSettingsView is a view that offers controls for hidden settings.
/// This is a developer-only tool to temporarily hide certain key features of the app.
struct DevelopmentSettingsView: View {
    
    // MARK: - Properties
    
    /// `true` if the app needs to display a button that presents the barcode scanning view.
    ///
    /// The view persists this Boolean value in `UserDefaults`.
    @AppStorage("barcode-scanning-available") var isBarcodeScanningAvailable = true
    
    // MARK: - View
    
    var body: some View {
        NavigationView {
            settingsList
                .navigationBarTitle("Development Settings", displayMode: .inline)
        }
    }
    
    private var settingsList: some View {
        List {
            Section(header: Text("Features")) {
                Toggle("Barcode Scanning", isOn: $isBarcodeScanningAvailable)
            }
            Section(header: Text("Reset")) {
                Button("Reset Recent Albums") {
                    RecentAlbumsStorage.shared.reset()
                }
            }
        }
    }
}

// MARK: - Previews

struct DevelopmentSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DevelopmentSettingsView()
    }
}
