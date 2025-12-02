/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to show details of a selected domain.
*/

import SwiftUI
import FileProvider
import Common

struct DomainDetailView: View {
    let entry: DomainObserver.DomainEntry
    @Binding var selectedDomain: DomainObserver.DomainEntry?
    @State var showingPending = false
    @State var showingMaterialized = false
    @State var showingBrowse = false
    @State var signalStatus = ""

    let warning = "FruitBasket does not implement push notifications. Manually signal the domain to trigger a check for updates."
    var body: some View {
        Form {
            Section(header: Text("Domain"), footer: Text(warning)) {
                HStack {
                    Text("Display name")
                    Spacer()
                    Text(entry.domain.displayName)
                }
                HStack {
                    Text("Identifier")
                    Spacer()
                    Text(entry.domain.identifier.rawValue)
                }
                Button(action: {
                    NSFileProviderManager(for: entry.domain)!.signalEnumerator(for: .workingSet) {
                        err in
                        if let err = err {
                            signalStatus = "\(err.localizedDescription)"
                        } else {
                            signalStatus = "Signalled at \(Date())"
                        }
                    }
                }) {
                    HStack {
                        Text("Signal domain")
                        Spacer()
                        Text(signalStatus)
                            .foregroundColor(.gray)
                    }
                }
            }
            Section {
                Button(action: {
                    NSFileProviderManager.remove(entry.domain, completionHandler: {
                        _ in
                        selectedDomain = nil
                    })
                }) {
                    Text("Remove domain")
                }
                .foregroundColor(.red)
            }

        }
    }
}
