/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A location that a webview can render.
*/

import Foundation

public enum WebViewDestination: Hashable, Equatable, Codable {
  case url(URL)
  case htmlString(String)
  case localFile(URL)
}

extension WebViewDestination {
  
  public var displayName: String {
    switch self {
    case .url(let url):
      return url.absoluteString
    case .htmlString(let string):
      return "raw html (\(string.count) characters)"
    case .localFile(let url):
      return "local file: \(url.lastPathComponent)"
    }
  }
  
  public var url: URL? {
    switch self {
    case .url(let url):
      return url
    case .localFile(let url):
      return url
    default:
      return nil
    }
  }
}
