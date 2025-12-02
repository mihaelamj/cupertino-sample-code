/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data that a browser page uses to configure its presentation.
*/

import CustomBrowserEngine
import SwiftUI
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: BrowserPageViewModel.self))

@MainActor
public class BrowserPageViewModel: ObservableObject {
  
  public enum NavigationDirection {
    case back
    case forward
  }
  
  @Published public private(set) var selectedtab: TabViewModel? = nil
  
  @Published public private(set) var tabs: [TabViewModel] = []
  
  /// A Boolean value that indicates whether there is a valid forward item in the back-forward list.
  @Published public private(set) var canGoForward: Bool = false
  
  /// A Boolean value that indicates whether there is a valid back item in the back-forward list.
  @Published public private(set) var canGoBack: Bool = false
  
  /// A Boolean value that indicates whether the view is currently loading content.
  @Published public private(set) var isLoading: Bool = false
  
  /// Setting this to true shows the list of all open tabs.
  @Published public var showTabs: Bool = false
  
  /// The string that appears in the search bar the top of the page.
  @Published public var searchBarString: String = ""
  
  nonisolated init() { }
  
  public func setShowTabs(_ newValue: Bool) {
    withAnimation {
      if newValue {
        selectedtab?.webView.didBecomeInactive()
      } else {
        selectedtab?.webView.didBecomeActive()
      }
      showTabs = newValue
    }
  }
}

// MARK: -

extension BrowserPageViewModel: WebViewNavigationNelegate {
  
  public func webView(_ webView: WebView, failedToNavigateTo destination: WebViewDestination, error: any Error) {
    Task { @MainActor in
      if let tab = tabs.first(where: { $0.webView == webView }) {
        tab.error = error
        if tab == selectedtab {
          updateNavigationState(with: webView)
        }
      }
    }
  }
  
  public func webView(_ webView: WebView, finishedNavigatingTo destination: WebViewDestination) {
    Task { @MainActor in
      if let tab = tabs.first(where: { $0.webView == webView }) {
        tab.destination = destination
        tab.displayName = destination.displayName
        if tab == selectedtab {
          updateNavigationState(with: webView)
        }
      }
    }
  }
  
  public func webViewContentProcessDidTerminate(_ webView: WebView, error: Error?) {
    Task { @MainActor in
      for tab in tabs where tab.webView.id == webView.id {
        tab.error = error
      }
    }
  }
}

// MARK: -

extension BrowserPageViewModel: WebViewUIDelegate {
  
  public func webViewDidStartLoading(_ webView: WebView) {
    guard webView == selectedtab?.webView else { return }
    updateLoadingState(with: webView)
  }
  
  public func webViewDidStopLoading(_ webView: WebView) {
    guard webView == selectedtab?.webView else { return }
    updateLoadingState(with: webView)
  }
  
  private func updateNavigationState(with webView: WebView?) {
    Task { @MainActor in
      self.canGoBack = webView?.canGoBack ?? false
      self.canGoForward = webView?.canGoForward ?? false
      self.searchBarString = webView?.destination?.displayName ?? ""
    }
  }
  
  private func updateLoadingState(with webView: WebView?) {
    Task { @MainActor in
      self.isLoading = webView?.isLoading ?? false
    }
  }
}

// MARK: -

extension BrowserPageViewModel {
  
  /// Navigates the current tab to the given destination.
  public func load(_ destination: WebViewDestination) {
    if let currentWebView = selectedtab?.webView {
      currentWebView.load(destination)
    } else {
      log.error("unable to load destination: currentTab is nil")
    }
  }
  
  /// Navigates the current tab forward or back.
  public func go(_ direction: NavigationDirection) {
    guard let currentWebView = selectedtab?.webView else { return }
    switch direction {
    case .back:
      if currentWebView.canGoBack {
        currentWebView.goBack()
      }
    case .forward:
      currentWebView.goForward()
    }
  }
  
  /// Refreshes the current web view, reloading its current page.
  public func refresh() {
    if let currentWebView = selectedtab?.webView, let destination = currentWebView.destination {
      currentWebView.load(destination)
    } else {
      log.error("unable to reload: current web view destination is nil")
    }
  }
}

// MARK: -

extension BrowserPageViewModel {
  
  /// Brings a tab to the forefront.
  ///
  /// This updates the published properties (like `canGoBack`, `isLoading`, etc ) based on the new active tab's current state.
  public func activateTab(_ tab: TabViewModel) {
    selectedtab = tab
    updateNavigationState(with: tab.webView)
    updateLoadingState(with: tab.webView)
    setShowTabs(false)
  }
  
  /// Creates a new tab.
  ///
  /// - Parameters:
  ///   - destination: The initial destination to load in the tab (default: `nil`).
  ///   - activate: If true (default), the new tab will become the current active / foreground tab.
  ///
  public func createNewTab(destination: WebViewDestination? = nil, activate: Bool) async throws {
    log.log("creating new tab with destination \(String(describing: destination))")
    
    let webView = try await WebView(frame: UIScreen.main.bounds)
    webView.navigationDelegate = self
    webView.uiDelegate = self
    
    let newTab = TabViewModel(webView: webView)
    log.log("created new tab \(newTab.id)")
    
    tabs += [newTab]
    
    if activate {
      activateTab(newTab)
      setShowTabs(false)
    }
    
    if let destination {
      newTab.webView.load(destination)
    }
  }
  
  /// Closes the given tab. If the selected tab is closed, the app selects the most recently open tab.
  public func closeTab(id: UUID) {
    log.log("closing tab \(id.uuidString)")
    
    if let index = tabs.firstIndex(where: { $0.id == id }) {
      let tab = tabs.remove(at: index)
    }
    
    if selectedtab?.id == id {
      selectedtab = tabs.last
    }
  }
}
