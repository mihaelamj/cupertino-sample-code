/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Information about a browser tab.
*/

import CustomBrowserEngine
import Foundation

public class TabViewModel: ObservableObject {
  
  public let webView: WebView
  
  public let creationDate: Date
  
  @Published public var error: Error? = nil
    
  @Published public var displayName: String
  
  @Published public var destination: WebViewDestination?
  
  init(webView: WebView, creationDate: Date = .now) {
    self.webView = webView
    self.displayName = webView.destination?.displayName ?? "New Tab"
    self.destination = webView.destination
    self.creationDate = creationDate
  }
}

// MARK: -

extension TabViewModel: Equatable, Identifiable {
  
  public var id: UUID {
    return webView.id
  }
  
  public static func == (lhs: TabViewModel, rhs: TabViewModel) -> Bool {
    return lhs.id == rhs.id
  }
}
