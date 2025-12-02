/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A message that requests an XPC endpoint over an XPC connection, and a type that encapsulates the endpoint in a reply.
*/

import XPC

/// Asks the extension to send back an endpoint
///
public struct GetXPCEndpointMessage: XPCCodable, Codable {
  public static var messageType: String = "get-xpc-endpoint-message"
}

public struct XPCEndpointMessage: XPCCodable {
  
  public static var messageType: String = "xpc-endpoint-message"
  
  private static let valueKey = "xpc-endpoint"
  
  public var endpoint: xpc_endpoint_t
  
  public init(endpoint: xpc_endpoint_t) {
    self.endpoint = endpoint
  }
  
  public func encode(into dict: xpc_object_t) throws {
    xpc_dictionary_set_value(dict, Self.valueKey, endpoint)
  }
  
  public static func decode(from dict: xpc_object_t) throws -> XPCEndpointMessage {
    guard let endpoint = xpc_dictionary_get_value(dict, Self.valueKey) else {
      throw XPCError.invalidKey(Self.valueKey)
    }
    return .init(endpoint: endpoint)
  }
}
