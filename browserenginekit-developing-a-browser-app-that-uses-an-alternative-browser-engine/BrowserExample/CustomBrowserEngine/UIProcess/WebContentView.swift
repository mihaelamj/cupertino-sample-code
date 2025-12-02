/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A content view that communicates with the rendering extension to display text.
*/

import UIKit
import BrowserEngineKit
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: WebContentView.self))

/// An text based view that displays web content managed by a content process and rendered by the rendering process.
public class WebContentView: UIView {
  
  public let id: PageID
  
  private let processPool: BrowserProcessPool
  
  /// The parent web view that contains this content view
  public weak var webView: WebView?
  
  /// The main interface to the content extension
  private var webContentProxy: WebContentExtensionProxy
  
  /// Renders the text of the web page
  private var textView: UITextView
  
  /// An interaction that comunicates this view's visibility to its content extension
  private var contentProcessInteraction: UIInteraction? = nil
  
  /// An interaction that comunicates this view's visibility to the rendering extension
  private var renderingProcessInteraction: UIInteraction? = nil
  
  /// Creates a new web content view and launches the requred extension processes
  ///
  public init(id: PageID = .init(),
              frame: CGRect = .zero,
              processPool: BrowserProcessPool) async throws {
    self.id = id
    self.processPool = processPool
    
    let webContentProxy = try await processPool.launchProcesses(id: id)
    self.webContentProxy = webContentProxy
    self.textView = UITextView(frame: frame)
    
    super.init(frame: frame)
    
    textView.delegate = self
    textView.isEditable = false
    addOverlay(textView)
    
    let contentProcessInteraction = processPool.getContentProcessViewInteraction(id: id)
    setContentProcessInteraction(contentProcessInteraction)
    
    let renderingProcessInteraction = processPool.getRenderingProcessViewInteraction()
    setRenderingProcessInteraction(renderingProcessInteraction)
  }
  
  required convenience init?(coder: NSCoder) {
    fatalError("not implemented")
  }
  
  deinit {
    processPool.invalidateContentProcess(for: id)
  }
}

// MARK: - UIContextMenuInteractionDelegate

extension WebContentView: UIContextMenuInteractionDelegate {
  
  public func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                     configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
    return BEContextMenuConfiguration(identifier: nil,
                                      previewProvider: nil,
                                      actionProvider: nil)
  }
}

// MARK: - UIInteractions

extension WebContentView {
  
  public func setRenderingProcessInteraction(_ newInteraction: UIInteraction?) {
    if let renderingProcessInteraction {
      log.log("removing rendering process interaction: \(String(describing: renderingProcessInteraction))")
      self.removeInteraction(renderingProcessInteraction)
    }
    if let newInteraction {
      log.log("adding rendering process interaction: \(String(describing: newInteraction))")
      self.addInteraction(newInteraction)
    }
  }
  
  public func setContentProcessInteraction(_ newInteraction: UIInteraction?) {
    if let contentProcessInteraction {
      log.log("removing content process interaction: \(String(describing: contentProcessInteraction))")
      self.removeInteraction(contentProcessInteraction)
    }
    if let newInteraction {
      log.log("adding content process interaction: \(String(describing: newInteraction))")
      self.addInteraction(newInteraction)
    }
  }
}

// MARK: - Capabilities

extension WebContentView {
  
  /// Applies the foreground process grant to the view's content process
  ///
  func foreground() {
    log.log("requesting foreground runtime cabability")
    processPool.grantCapability(.foreground, pageID: id)
  }
  
  /// Applies the background process grant to the view's content process
  ///
  func background() {
    log.log("requesting background runtime cabability")
    processPool.grantCapability(.background, pageID: id)
  }
}

// MARK: - Content Loading

extension WebContentView {
  
  public func load(_ destination: WebViewDestination) async throws {
    let result = try await webContentProxy.load(destination: destination, pageID: self.id)
    let displayString = parse(result: result)
    textView.attributedText = displayString
    textView.scrollRangeToVisible(.init(location: 0, length: 0)) // scroll to top
  }
  
  /// Parses the network result into the attributed string that gets displayed to the user
  ///
  private func parse(result: NetworkTaskResult) -> NSAttributedString {
    if let data = result.data {
      do {
        return try NSAttributedString(data: data, options: [
          .documentType: NSAttributedString.DocumentType.html,
          .characterEncoding: String.Encoding.utf8.rawValue
        ], documentAttributes: nil)
      } catch let error {
        return .init(string: "Failed to parse result: \(String(describing: error))")
      }
    } else if let error = result.error {
      return .init(string: String(describing: error))
    } else {
      return .init(string: "?")
    }
  }
}

// MARK: -

extension WebContentView: UITextViewDelegate {
  
  public func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
    if case let .link(url) = textItem.content, let resolvedURL = resolve(url) {
      return UIAction { _ in self.webView?.load(.url(resolvedURL)) }
    } else {
      return defaultAction
    }
  }
  
  /// The parsed HTML may convert relative links to use the scheme `applewebdata://<uuid>/<relative path>`.
  /// This function resolves those types of URLs against the current base URL
  ///
  private func resolve(_ url: URL) -> URL? {
    guard url.scheme == "applewebdata" else {
      return url // already resolved
    }
    guard case let .url(currentURL) = webView?.destination else {
      return nil
    }
    let path = url.pathComponents.dropFirst().joined(separator: "/")
    var components = URLComponents()
    components.scheme = currentURL.scheme
    components.host = currentURL.host
    components.path = "/\(path)"
    return components.url
  }
}
