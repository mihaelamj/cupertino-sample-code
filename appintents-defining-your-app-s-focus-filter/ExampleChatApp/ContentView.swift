/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view of the iOS app.
*/

import SwiftUI

struct ContentView: View {
    @AppStorage("AppData", store: Repository.suiteUserDefaults)
    var appData: Data = Data()
    
    @State var displayedError: String?
    @State var viewModel = ContentViewModel(appDataModel: AppDataModel())
    
    var body: some View {
        NavigationView {
            List {
                if let displayedError = displayedError {
                    titleAndSubtitleView(title: "Error",
                                         subtitle: displayedError)
                }
                titleAndSubtitleView(title: "Always use dark mode",
                                     subtitle: viewModel.alwaysUseDarkMode)
                titleAndSubtitleView(title: "Away status",
                                     subtitle: viewModel.status)
                titleAndSubtitleView(title: "Selected account",
                                     subtitle: viewModel.selectedAccount)
            }
            .listStyle(InsetGroupedListStyle())
            .preferredColorScheme(viewModel.alwaysUseDarkModeBoolValue ? .dark : .light)
            .navigationTitle(Text(viewModel.focusFilterState))
        }
        .onChange(of: appData) { newValue in
            let decoder = JSONDecoder()
            guard let appDataModelDecoded = try? decoder.decode(AppDataModel.self, from: newValue) else {
                displayedError = "Failed to decode AppData"
                return
            }
            viewModel = ContentViewModel(appDataModel: appDataModelDecoded)
        }
    }
    
    private func titleAndSubtitleView(title: String, subtitle: String) -> some View {
        Section(title) {
            Text(subtitle)
        }
    }
}

struct ContentViewModel {
    var focusFilterState: String
    var alwaysUseDarkMode: String
    var alwaysUseDarkModeBoolValue: Bool
    var status: String
    var selectedAccount: String
    
    init(appDataModel: AppDataModel) {
        self.focusFilterState = "Filter \(appDataModel.isFocusFilterEnabled ? "On" : "Off")"
        self.alwaysUseDarkModeBoolValue = appDataModel.alwaysUseDarkMode
        self.alwaysUseDarkMode = appDataModel.alwaysUseDarkMode ? "True" : "False"
        self.status = appDataModel.status ?? "Not set"
        if let selectedAccountID = appDataModel.selectedAccountID {
            do {
                let account = try Repository.shared.accountEntity(identifier: selectedAccountID)
                selectedAccount = account.displayName
            } catch {
                selectedAccount = "Error: \(error.localizedDescription)"
            }
        } else {
            selectedAccount = "None selected"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // The Filter On preview.
        ContentView(viewModel:
                        ContentViewModel(appDataModel:
                                            AppDataModel(alwaysUseDarkMode: true,
                                                         status: "In a meeting",
                                                         selectedAccountID: "work-account-identifier")))
        // The Filter Off preview.
        ContentView()
    }
}
