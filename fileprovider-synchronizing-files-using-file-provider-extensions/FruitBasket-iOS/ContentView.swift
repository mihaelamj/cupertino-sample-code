/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top-level view of the app, allowing access to settings and the domain list.
*/

import SwiftUI

struct ContentView: View {
    typealias DomainEntry = DomainObserver.DomainEntry
    enum NavigationPane: Hashable {
        case domainDetails(DomainEntry)
    }

    enum ActiveSheet: Identifiable, Hashable {
        var id: ActiveSheet { self }
        case settings
        case addDomain
    }

    @State var navigationState = NavigationPath()
    @State var activeSheet: ActiveSheet? = nil
    @State var shownDomain: DomainEntry? = nil

    @ObservedObject var domainObserver = DomainObserver()

    var body: some View {
        let selectedDomainBinding = Binding<DomainEntry?>(get: {
            return shownDomain
        }, set: { sel in
            if let sel = sel {
                shownDomain = sel
                navigationState = NavigationPath([NavigationPane.domainDetails(sel)])
            } else {
                shownDomain = nil
                navigationState = NavigationPath()
            }
        })

        NavigationSplitView {
            DomainList(domains: $domainObserver.domains, selectedDomain: selectedDomainBinding)
                .navigationBarItems(trailing: HStack {
                    Button {
                        activeSheet = .settings
                    } label: {
                        Image(systemName: "gear")
                    }
                    Button {
                        activeSheet = .addDomain
                    } label: {
                        Image(systemName: "plus")
                    }
                })
        } detail: {
            NavigationStack(path: $navigationState) {
                Text("No selection")
                    .navigationDestination(for: NavigationPane.self) { state in
                        switch state {
                        case .domainDetails(let entry):
                            DomainDetailView(entry: entry, selectedDomain: selectedDomainBinding)
                        }
                    }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView(activeSheet: $activeSheet)
            case .addDomain:
                AddDomain(domainObserver: domainObserver, activeSheet: $activeSheet)
            }
        }
    }
}
