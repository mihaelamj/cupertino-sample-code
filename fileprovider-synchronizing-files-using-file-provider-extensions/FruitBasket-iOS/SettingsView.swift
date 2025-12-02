/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that manages settings, including remote host selection using Bonjour.
*/

import SwiftUI
import Common
import os.log

struct SettingsView: View {
    public var loggingCategory: OSLog = OSLog(subsystem: "com.example.FruitBasket", category: "settings")
    @AppStorage(wrappedValue: "", "hostname", store: UserDefaults.sharedContainerDefaults) var hostname: String
    @State var navigationState = NavigationPath()
    @State var host: HostListEntry? = nil
    @Binding var activeSheet: ContentView.ActiveSheet?

    @ObservedObject var browser = ServiceBrowser()
    enum SubSettings: Equatable {
        case hostname
    }

    var body: some View {
        let hostnameBinding = Binding<HostListEntry?> { host ??
            HostListEntry(name: "", address: hostname)
        } set: { newValue in
            $host.wrappedValue = newValue
            $hostname.wrappedValue = newValue?.address ?? ""
        }

        NavigationStack(path: $navigationState) {
            Form {
                Section(header: Text("Server")) {
                    HStack {
                        TextField("Host name", text: Binding { UserDefaults.sharedContainerDefaults.hostname
                        } set: { newValue in
                            $host.wrappedValue = nil
                            $hostname.wrappedValue = newValue
                        })
                        if let found = browser.hosts.first(where: { $0.address == UserDefaults.sharedContainerDefaults.hostname }) {
                            Spacer()
                            Text(found.name).foregroundColor(.gray)
                        }
                    }

                    NavigationLink(value: SubSettings.hostname) {
                        Text("Local servers")
                        Spacer()

                        if !browser.hosts.isEmpty {
                            Text("\(browser.hosts.count) found").foregroundColor(.gray)
                        } else {
                            switch browser.state {
                            case .browsing:
                                ProgressView()
                            case .error(let text):
                                Text(text)
                            case .stopped:
                                Spacer()
                            }
                        }
                    }
                    .disabled(browser.hosts.isEmpty)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", role: .cancel) {
                        activeSheet = nil
                    }
                }
            }
            .navigationDestination(for: SubSettings.self) { setting in
                switch setting {
                case .hostname:
                    HostList(hosts: $browser.hosts, selectedHost: hostnameBinding, navigationState: $navigationState)
                }
            }
            .navigationBarTitle("Settings")
        }
    }

    class ServiceBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate, ObservableObject {
        let logger = Logger(subsystem: "com.example.FruitBasket", category: "settings.browser")

        @Published var hosts = [HostListEntry]()

        struct ServiceEntry {
            let entry: HostListEntry?
            let service: NetService
        }

        var services: [ServiceEntry] {
            didSet {
                hosts = services.compactMap { $0.entry }
            }
        }

        enum State {
            case browsing
            case stopped
            case error(String)
        }
        @Published var state = State.browsing

        internal let browser: NetServiceBrowser
        override init() {
            browser = NetServiceBrowser()
            services = [ServiceEntry]()

            super.init()
            browser.delegate = self
            browser.searchForServices(ofType: "_fruitbasket._tcp.", inDomain: "")
        }

        func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
            logger.info("Search about to begin")
        }

        func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
            service.delegate = self
            service.resolve(withTimeout: 10)

            // Store an address-less entry for this service, just to hold on to it.
            services.append(ServiceEntry(entry: nil, service: service))
            logger.info("found \(service)")
        }

        func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
            logger.info("lost \(service)")
            services.removeAll { entry in
                entry.service == service
            }
        }
        func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
            state = .error("\(errorDict)")
        }
        func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
            state = .stopped
        }

        func netServiceDidResolveAddress(_ sender: NetService) {
            guard let addresses = sender.addresses else {
                return
            }
            for data in addresses {
                if let addr = parseAddress(data),
                   !addr.hasPrefix("169.254.") {
                    // Remove existing entries for this address (and also the empty one).
                    services.removeAll { (service) -> Bool in
                        if let entry = service.entry {
                            return entry.address == addr
                        }
                        return true
                    }
                    services.append(ServiceEntry(entry: SettingsView.HostListEntry(name: sender.name, address: addr), service: sender))
                }
            }
        }

        func parseAddress(_ data: Data) -> String? {
            guard data.count >= MemoryLayout<sockaddr>.size else {
                return nil
            }

            let addr = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in ptr.load(as: sockaddr.self) }
            if Int32(addr.sa_family) == AF_INET {
                guard data.count >= MemoryLayout<sockaddr_in>.size else {
                    return nil
                }
                let addr4 = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in ptr.load(as: sockaddr_in.self) }
                return String(cString: inet_ntoa(addr4.sin_addr))
            }
            return nil
        }
    }

    struct HostListEntry: Identifiable, Equatable {
        var id: String {
            address
        }
        var name: String
        var address: String
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.address == rhs.address
        }
    }

    struct HostList: View {
        @Binding var hosts: [HostListEntry]
        @Binding var selectedHost: HostListEntry?
        @Binding var navigationState: NavigationPath

        var body: some View {
            Form {
                List {
                    ForEach(hosts) { host in
                        Button {
                            selectedHost = host
                            navigationState.removeLast()
                        } label: {
                            HStack {
                                Text("\(host.name)").foregroundColor(.black)
                                Text(" \(host.address)").foregroundColor(.gray)
                                Spacer()
                                if host == selectedHost {
                                    Image(systemName: "checkmark").foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }.navigationBarTitleDisplayMode(.inline)
        }
    }
}
