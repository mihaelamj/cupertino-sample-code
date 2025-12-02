/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI entry point for the app, that shows its main view and handles requests to open URLs.
*/

import SwiftUI
import CustomBrowserEngine

@main
struct BrowserApp: App {
  
  @State var browserPageViewModel = BrowserPageViewModel()
  
  @State var alertManager = AlertManager()
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        BrowserPage(model: browserPageViewModel)
          .navigationTitle("Browser Example")
          .navigationBarTitleDisplayMode(.inline)
      }
      .presentingAlerts(from: alertManager)
      .environmentObject(alertManager)
      .onOpenURL { open($0) }
    }
  }
  
  private func open(_ url: URL) {
    Task {
      do {
        try await browserPageViewModel.createNewTab(destination: .url(url), activate: true)
      } catch let error {
        await alertManager.present(error: error, title: "Failed to open url")
      }
    }
  }
}
