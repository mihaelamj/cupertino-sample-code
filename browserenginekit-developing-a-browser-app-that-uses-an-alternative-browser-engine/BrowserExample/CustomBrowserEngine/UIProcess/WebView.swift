/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A web view that renders pages using the browser's custom engine.
*/

import Foundation
import BrowserEngineKit
import UIKit
import os.log

public typealias PageID = UUID

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: WebView.self))

public protocol WebViewNavigationNelegate: AnyObject {
  func webView(_ webView: WebView, failedToNavigateTo destination: WebViewDestination, error: Error)
  func webView(_ webView: WebView, finishedNavigatingTo destination: WebViewDestination)
  func webViewContentProcessDidTerminate(_ webView: WebView, error: Error?)
}

public protocol WebViewUIDelegate: AnyObject {
  func webViewDidStartLoading(_ webView: WebView)
  func webViewDidStopLoading(_ webView: WebView)
}

// MARK: -

/// A custom web view that renders web pages using the browser engine.
public class WebView: UIView {
  
  public var id: PageID { return contentView.id }
  
  public weak var navigationDelegate: WebViewNavigationNelegate?
  
  public weak var uiDelegate: WebViewUIDelegate?
  
  private var navigationStack: WebViewNavigationStack = .init()
  
  /// The backing view the app uses for rendering web page content.
  private var contentView: WebContentView
  
  /// The current destination (URL, or raw HTML string) that the web view is currently loading or displaying.
  public private(set) var destination: WebViewDestination? = nil
  
  /// A Boolean value that indicates whether there is a valid back item in the back-forward list.
  public var canGoBack: Bool { navigationStack.backItem != nil }
  
  /// A Boolean value that indicates whether there is a valid forward item in the back-forward list.
  public var canGoForward: Bool { navigationStack.forwardItem != nil }
  
  /// A Boolean value that indicates whether the view is currently loading content.
  public private(set) var isLoading: Bool = false
  
  /// Note: This is initializer is asynchronous since the app may have to wait for the helper extension processes to launch.
  public init(frame: CGRect = .zero,
              uiDelegate: WebViewUIDelegate? = nil,
              navigationDelegate: WebViewNavigationNelegate? = nil) async throws {
    self.uiDelegate = uiDelegate
    self.navigationDelegate = navigationDelegate
    self.contentView = try await WebContentView(frame: frame, processPool: .shared)
    super.init(frame: frame)
    contentView.webView = self
    addOverlay(contentView)
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: -

extension WebView {
  
  public func didBecomeActive() {
    contentView.foreground()
  }
  
  public func didBecomeInactive() {
    contentView.background()
  }
}

// MARK: -

extension WebView {
  
  /// Navigates the web view to the given destination.
  public func load(_ destination: WebViewDestination, updateNavigationStack: Bool = true) {
    Task {
      isLoading = true
      uiDelegate?.webViewDidStartLoading(self)
      do {
        try await contentView.load(destination)
        self.destination = destination
        navigationDelegate?.webView(self, finishedNavigatingTo: destination)
        if updateNavigationStack {
          navigationStack.push(destination)
        }
      } catch let error {
        navigationDelegate?.webView(self, failedToNavigateTo: destination, error: error)
      }
      isLoading = false
      uiDelegate?.webViewDidStopLoading(self)
    }
  }
  
  /// Navigates the web view to the previous page.
  public func goBack() {
    if canGoBack, let destination = navigationStack.goBack() {
      load(destination, updateNavigationStack: false)
    } else {
      log.error("failed to navigate back")
    }
  }
  
  /// Navigates the web view to the next page.
  public func goForward() {
    if canGoForward, let destination = navigationStack.goForward() {
      load(destination, updateNavigationStack: false)
    } else {
      log.error("failed to navigate forward")
    }
  }
}

// MARK: -

internal class WebViewNavigationStack {
  
  private(set) var currentItem: WebViewDestination?
  
  private(set) var backList: Stack<WebViewDestination>
  
  var backItem: WebViewDestination? {
    return backList.peek()
  }
  
  private(set) var forwardList: Stack<WebViewDestination>
  
  var forwardItem: WebViewDestination? {
    return forwardList.peek()
  }
  
  init(currentItem: WebViewDestination? = nil,
       forwardList: Stack<WebViewDestination> = .init(),
       backList: Stack<WebViewDestination> = .init()) {
    self.backList = backList
    self.forwardList = forwardList
    self.currentItem = currentItem
  }
  
  public func push(_ destination: WebViewDestination) {
    if let currentItem { backList.push(currentItem) }
    currentItem = destination
    forwardList.removeAll()
  }
  
  public func goForward() -> WebViewDestination? {
    guard let destination = forwardList.pop() else { return nil }
    if let currentItem { backList.push(currentItem) }
    currentItem = destination
    return destination
  }
  
  public func goBack() -> WebViewDestination? {
    guard let destination = backList.pop() else { return nil }
    if let currentItem { forwardList.push(currentItem) }
    currentItem = destination
    return destination
  }
}

// MARK: -

extension UIView {
  
  public func addOverlay(_ view: UIView) {
    addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: leadingAnchor),
      view.trailingAnchor.constraint(equalTo: trailingAnchor),
      view.topAnchor.constraint(equalTo: topAnchor),
      view.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }
}
