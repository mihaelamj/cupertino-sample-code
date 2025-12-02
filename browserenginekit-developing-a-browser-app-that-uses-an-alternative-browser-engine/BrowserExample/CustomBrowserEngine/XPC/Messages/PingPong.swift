/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Types that represent ping messages and their replies that are sent over XPC connections.
*/

import XPC

struct XPCPing: XPCCodable {
  
  static var messageType: String = "ping"
  
  func encode(into dict: xpc_object_t) throws {
    xpc_dictionary_set_string(dict, XPCMessageType, Self.messageType)
  }
  
  static func decode(from dict: xpc_object_t) throws -> XPCPing {
    guard let tmp = xpc_dictionary_get_string(dict, XPCMessageType), String(cString: tmp) == Self.messageType else {
      throw BrowserEngineError("message type is not \(Self.messageType)")
    }
    return .init()
  }
}

// MARK: -

struct XPCPong: XPCCodable {
  
  static var messageType: String = "pong"
  
  func encode(into dict: xpc_object_t) throws {
    xpc_dictionary_set_string(dict, XPCMessageType, Self.messageType)
  }
  
  static func decode(from dict: xpc_object_t) throws -> XPCPong {
    guard let tmp = xpc_dictionary_get_string(dict, XPCMessageType), String(cString: tmp) == Self.messageType else {
      throw BrowserEngineError("message type is not \(Self.messageType)")
    }
    return .init()
  }
}
