/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Messages that the browser app sends to, and receives from, its networking extension.
*/

import Foundation
import XPC

public enum NetworkExtensionTask: Codable, XPCCodable {
  
  public static let messageType: String = "net-ext-task"
  
  case data(URL)
  case download(URL)
  case upload(URL, body: Data)
}

// MARK: -

public struct NetworkTaskResult: Codable, XPCCodable {
  
  public static let messageType: String = "net-ext-task-result"
  
  public var response: HTTPResponse?
  public var data: Data?
  public var error: String?
  
  public init(response: HTTPURLResponse?, data: Data?, error: Error?) {
    if let response { self.response = .init(httpURLResponse: response) }
    self.data = data
    self.error = error?.localizedDescription
  }
}

// MARK: -

/// A simplified and codable version of `HTTPURLResponse`
///
public struct HTTPResponse: Codable {
  var statusCode: Int
  var headers: [String: String]
}

extension HTTPResponse {
  
  init(httpURLResponse: HTTPURLResponse) {
    self.statusCode = httpURLResponse.statusCode
    let mappedHeaderFields = httpURLResponse.allHeaderFields.map { (String(describing: $0), String(describing: $1)) }
    self.headers = .init(uniqueKeysWithValues: mappedHeaderFields)
  }
}
