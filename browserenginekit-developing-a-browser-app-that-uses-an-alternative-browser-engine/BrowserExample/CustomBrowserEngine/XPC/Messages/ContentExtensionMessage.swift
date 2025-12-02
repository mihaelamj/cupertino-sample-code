/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Messages that the browser app sends to, and receives from, web content extensions.
*/

import XPC

public enum WebContentExtensionTask: Codable, XPCCodable {
  public static let messageType: String = "content-ext-task"
  case load(destination: WebViewDestination, pageID: PageID)
}

// MARK: -

public struct WebContentExtensionBootstrapCommand: XPCCodable {
  
  public static let messageType: String = "content-ext-bootstrap"
  
  enum Key {
    static let RenderingEndpoint = "rendering-endpoint"
    static let NetworkEndpoint = "network-endpoint"
  }
  
  public var renderingEndpoint: xpc_endpoint_t
  public var networkEndpoint: xpc_endpoint_t
  
  public func encode(into dict: xpc_object_t) throws {
    xpc_dictionary_set_value(dict, Key.RenderingEndpoint, renderingEndpoint)
    xpc_dictionary_set_value(dict, Key.NetworkEndpoint, networkEndpoint)
  }
  
  public static func decode(from dict: xpc_object_t) throws -> WebContentExtensionBootstrapCommand {
    guard let renderingEndpoint = xpc_dictionary_get_value(dict, Key.RenderingEndpoint) else {
      throw BrowserEngineError("xpc_dictionary_get_value failed for key \(Key.RenderingEndpoint)")
    }
    guard let networkEndpoint = xpc_dictionary_get_value(dict, Key.NetworkEndpoint) else {
      throw BrowserEngineError("xpc_dictionary_get_value failed for key \(Key.NetworkEndpoint)")
    }
    guard xpc_get_type(renderingEndpoint) == XPC_TYPE_ENDPOINT else {
      throw BrowserEngineError("renderingEndpoint is not of type XPC_TYPE_ENDPOINT")
    }
    guard xpc_get_type(networkEndpoint) == XPC_TYPE_ENDPOINT else {
      throw BrowserEngineError("networkEndpoint is not of type XPC_TYPE_ENDPOINT")
    }
    return .init(renderingEndpoint: renderingEndpoint, networkEndpoint: networkEndpoint)
  }
}
