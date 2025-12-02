/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that manages logging in to a remote domain.
*/

import SwiftUI
import Common
import Extension
import Combine

class AccountFetcher: ObservableObject {
    @AppStorage(wrappedValue: "", "hostname", store: UserDefaults.sharedContainerDefaults) var hostname: String
    @Published var accounts: Result<[AccountService.Account], CommonError>? = nil
    var connection: DomainConnection {
        DomainConnection.accountConnection(hostname: hostname, port: defaultPort)
    }

    init() {
        updateAccounts()
    }

    func addRemoteAccount(displayName: String, identifier: String, mirroring: String?, completionHandler: @escaping (Bool) -> Void) {
        accounts = nil
        connection.makeJSONCall(AccountService.CreateAccountParameter(displayName: displayName,
                                                                      identifier: identifier,
                                                                      mirroringAccount: mirroring,
                                                                      remoteOnly: true)) { resp in
            switch resp {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.accounts = .failure(error as? CommonError ?? CommonError.internalError)
                    completionHandler(false)
                }
            case .success:
                self.updateAccounts()
                DispatchQueue.main.async {
                    completionHandler(true)
                }
            }
        }
    }

    internal func updateAccounts() {
        connection.makeJSONCall(AccountService.ListAccountParameter()) { resp in
            DispatchQueue.main.async {
                switch resp {
                case .failure(let error):
                    self.accounts = .failure(error as? CommonError ?? CommonError.internalError)
                case .success(let resp):
                    self.accounts = .success(resp.accounts)
                }
            }
        }
    }
}

extension AccountService.Account: @retroactive Identifiable, @retroactive Hashable {
    public static func == (lhs: AccountService.Account, rhs: AccountService.Account) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    public var id: String {
        identifier
    }

    public func hash(into hasher: inout Hasher) {
        identifier.hash(into: &hasher)
    }
}

struct AddDomain: View {
    @ObservedObject var accountFetcher = AccountFetcher()
    @ObservedObject var domainObserver: DomainObserver
    @Binding var activeSheet: ContentView.ActiveSheet?

    var body: some View {
        NavigationStack {
            Group {
                if let fetch = accountFetcher.accounts {
                    switch fetch {
                    case .failure(let error):
                        Form {
                            Section(footer: Text("Check that you have a server selected in settings, and that it is running.")) {
                                Text("\(error.localizedDescription)")
                            }
                        }
                    case .success(let accounts):
                        let localDomains = domainObserver.domains
                        let availableAccounts = accounts.filter { (account) -> Bool in
                            !localDomains.contains { (domain) -> Bool in
                                domain.domain.identifier.rawValue == account.identifier
                            }
                        }
                        RemoteAccountView(accounts: availableAccounts,
                                          domainObserver: domainObserver,
                                          accountFetcher: accountFetcher,
                                          activeSheet: $activeSheet)
                    }
                } else {
                    Form {
                        Fetching()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", role: .cancel) {
                        activeSheet = nil
                    }
                }
            }
            .navigationTitle("Add remote account")
        }
    }

    struct RemoteAccountView: View {
        var accounts: [AccountService.Account]
        @ObservedObject var domainObserver: DomainObserver
        @ObservedObject var accountFetcher: AccountFetcher
        @ObservedObject var state = ViewState()
        @State var navigationState = NavigationPath()
        @Binding var activeSheet: ContentView.ActiveSheet?
        var sink: AnyCancellable?

        enum NavigationPane: Hashable {
            case remoteAccounts
        }

        class ViewState: ObservableObject {
            @MainActor @Published var selectedAccount: AccountService.Account? = nil
        }

        init(accounts: [AccountService.Account],
             domainObserver: DomainObserver,
             accountFetcher: AccountFetcher,
             activeSheet: Binding<ContentView.ActiveSheet?>) {
            self.accounts = accounts
            self.domainObserver = domainObserver
            self.accountFetcher = accountFetcher
            self._activeSheet = activeSheet

            // The combineLatest step takes the outputs of accountFetcher and domainObserver,
            // and filters the account (assuming it's valid) to include only accounts that
            // don't have a corresponding local domain.
            sink = accountFetcher.$accounts.combineLatest(domainObserver.$domains, {
                (result, domains) -> Result<[AccountService.Account], CommonError>? in
                return result?.map({ (accounts) -> [AccountService.Account] in
                    accounts.filter { (account) -> Bool in
                        !domains.contains { (entry) -> Bool in
                            entry.domain.identifier.rawValue == account.identifier
                        }
                    }
                })
            })
            // The sink stores only the result of the previous step, indirectly using the observed "state" helper,
            // so that everything updates correctly.
            .sink { [state] result in
                if case .success(let accounts) = result,
                   let first = accounts.first {
                        state.selectedAccount = first
                } else {
                    state.selectedAccount = nil
                }
            }
        }

        var body: some View {
            NavigationStack(path: $navigationState) {
                Form {
                    Section(header: Text("Remote accounts")) {
                        Button {
                            navigationState.append(NavigationPane.remoteAccounts)
                        } label: {
                            HStack {
                                Text("Account")
                                Spacer()
                                if let sel = state.selectedAccount {
                                    Text("\(sel.displayName)").foregroundColor(.gray)
                                } else {
                                    if accounts.isEmpty {
                                        Text("None eligible").foregroundColor(.gray)
                                    } else {
                                        Text("None selected").foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .disabled(accounts.isEmpty)
                    }
                    Section(footer: HStack {
                        if let selected = state.selectedAccount {
                            Text("Create a local domain for the existing remote account \"\(selected.displayName)\" (#\(selected.rootItem.id.id)).")
                        } else if accounts.isEmpty {
                            Text("There are no remote accounts that don't have a corresponding local domain.")
                        }
                    }) {
                        Button("Add local domain for selected account") {
                            guard let account = state.selectedAccount else {
                                return
                            }
                            domainObserver.addDomain(displayName: account.displayName, accountIdentifier: account.identifier)
                            activeSheet = nil
                        }
                        .disabled(state.selectedAccount == nil || accounts.isEmpty)
                    }
                }
                .navigationDestination(for: NavigationPane.self) { pane in
                    switch pane {
                    case .remoteAccounts:
                        AccountList(accounts: accounts,
                                    allowEmptySelection: false,
                                    selectedAccount: $state.selectedAccount,
                                    navigationState: $navigationState)
                    }
                }
            }
        }
    }

    struct AccountList: View {
        var accounts: [AccountService.Account]
        let allowEmptySelection: Bool
        @Binding var selectedAccount: AccountService.Account?
        @Binding var navigationState: NavigationPath

        var body: some View {
            Form {
                List {
                    if allowEmptySelection {
                        Button {
                            selectedAccount = nil
                            navigationState.removeLast()
                        } label: {
                            Text("None").foregroundColor(.black)
                        }
                    }
                    ForEach(accounts) { account in
                        Button {
                            selectedAccount = account
                            navigationState.removeLast()
                        } label: {
                            HStack {
                                Text("\(account.displayName)").foregroundColor(.black)
                                Text(" #\(account.rootItem.id.id)").foregroundColor(.gray)
                                Spacer()
                                if account == selectedAccount {
                                    Image(systemName: "checkmark").foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }.navigationBarTitleDisplayMode(.inline)

        }
    }

    // A simple spinner to show that the system is still doing something.
    struct Fetching: View {
        var body: some View {
            Section(header: Text("Accounts")) {
                HStack {
                    Text("Fetching accounts from server...")
                    Spacer()
                    ProgressView()
                }
            }
        }
    }
}
