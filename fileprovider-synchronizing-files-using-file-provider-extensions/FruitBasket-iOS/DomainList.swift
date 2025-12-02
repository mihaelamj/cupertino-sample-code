/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that lists logged-in domains.
*/

import SwiftUI
import Extension
import Common
import os.log

struct DomainList: View {
    @Binding var domains: [DomainObserver.DomainEntry]
    @Binding var selectedDomain: DomainObserver.DomainEntry?

    var body: some View {
        if domains.isEmpty {
            Text("No domains")
        } else {
            List {
                ForEach(domains) { entry in
                    let selected = selectedDomain == entry
                    Button {
                        selectedDomain = entry
                    } label: {
                        DomainListEntry(domain: entry.domain, selected: selected)
                    }
                    .listRowBackground(selected ? Color.accentColor : Color.clear)
                }
            }
            .navigationTitle("Domains")
            .listStyle(.insetGrouped)
        }
    }
}

