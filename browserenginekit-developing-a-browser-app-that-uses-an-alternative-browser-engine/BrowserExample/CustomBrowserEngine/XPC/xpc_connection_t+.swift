/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience methods to get additional information from XPC connections.
*/

import XPC
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: "xpc_connection_t")

public typealias XPCConnectionEventHandler = (xpc_object_t, xpc_connection_t) -> Void

extension xpc_connection_t {
  
  /// A wrapper arround `xpc_connection_activate` that adds aditional logging
  ///
  public func activate() {
    log.log("activating connection \(String(describing: self))")
    xpc_connection_activate(self)
  }
  
  /// A wrapper around `xpc_connection_set_event_handler` that also adds ping functionality and additional event logging
  ///
  public func setEventHandler(label: String, _ eventHandler: @escaping XPCConnectionEventHandler) {
    xpc_connection_set_event_handler(self) { event in
      
      log.log("[\(label)] handling event: \(String(describing: event))")
      
      let eventType = xpc_get_type(event)
      switch eventType {
      case XPC_TYPE_DICTIONARY:
        
        // handle ping messages
        if let cString = xpc_dictionary_get_string(event, XPCMessageType), String(cString: cString) == XPCPing.messageType {
          do {
            try self.send(XPCPong(), replyingTo: event)
          } catch let error {
            log.error("[\(label)] failed to pong: \(String(describing: error))")
          }
        } else {
          eventHandler(event, self)
        }
      
      case XPC_TYPE_CONNECTION:
        
        log.log("[\(label)] handling event of type XPC_TYPE_CONNECTION")
        let newConnection = event as xpc_connection_t
        newConnection.setEventHandler(label: label, eventHandler)
        newConnection.activate()
        
      case XPC_TYPE_ERROR:
        
        if xpc_equal(event, XPC_ERROR_CONNECTION_INVALID) {
          let reason = self.getInvalidationReason() ?? "nil"
          log.log("[\(label)] connection \(String(describing: self)) was invalidated with reason: \(reason)")
        } else if xpc_equal(event, XPC_ERROR_CONNECTION_INTERRUPTED) {
          log.log("[\(label)] connection \(String(describing: self)) was interrupted")
        }
      default:
        log.log("[\(label)] unexpected message type: \(String(describing: eventType))")
      }
    }
  }
}

// MARK: -

extension xpc_connection_t {
  
  /// Sets the requirement that the connected peer must have a boolean value of true for the given entitlement
  public func setBooleanEntitlementRequirement(_ entitlementKey: String) {
    #if !targetEnvironment(simulator)
    let result = xpc_connection_set_peer_entitlement_matches_value_requirement(self, entitlementKey, XPC_BOOL_TRUE)
    if result == KERN_SUCCESS {
      log.log("set peer entitlement requrement for \(entitlementKey)")
    } else {
      log.error("failed set peer entitlement requrement for \(entitlementKey): code \(result)")
    }
    #endif
  }
  
  /// Null if the connection has not been invalidated, otherwise a description for why the connection was invalidated.
  public func getInvalidationReason() -> String? {
    if let reason = xpc_connection_copy_invalidation_reason(self) {
      return String(cString: reason)
    } else {
      return nil
    }
  }
}

// MARK: -

extension xpc_connection_t {
  
  public func send<T: XPCCodable>(_ object: T, replyingTo message: xpc_object_t) throws {
    guard let reply = xpc_dictionary_create_reply(message) else {
      throw XPCError.failedToCreateReply
    }
    try encodeObject(object, into: reply)
    log.log("sending reply: \(String(describing: reply))")
    xpc_connection_send_message(self, reply)
  }
  
  public func send<T: XPCCodable>(_ object: T) throws {
    let message = xpc_dictionary_create(nil, nil, 0)
    try encodeObject(object, into: message)
    log.log("sending message: \(String(describing: message))")
    xpc_connection_send_message(self, message)
  }
  
  public func sendWithReply<T: XPCCodable>(_ object: T) async throws -> xpc_object_t {
    let message = xpc_dictionary_create(nil, nil, 0)
    try encodeObject(object, into: message)
    return try await withCheckedThrowingContinuation { continuation in
      log.log("sending message and waiting for reply: \(String(describing: message))")
      xpc_connection_send_message_with_reply(self, message, nil) { response in
        log.log("recieved reply: \(String(describing: response))")
        if xpc_get_type(response) == XPC_TYPE_ERROR {
          let description: String = response.getErrorDescription() ?? "nil"
          continuation.resume(throwing: BrowserEngineError("XPC_ERROR_KEY_DESCRIPTION: \(description)"))
        } else {
          continuation.resume(returning: response)
        }
      }
    }
  }
  
  public func sendWithReply<T: XPCCodable, S: XPCDecodable>(_ object: T, decodingReplyAs decodeType: S.Type) async throws -> S {
    let response = try await sendWithReply(object)
    do {
      return try S.decode(from: response)
    } catch let error {
      throw BrowserEngineError("failed to decode response as \(String(describing: S.self)): \(String(describing: error))")
    }
  }
  
  /// A helper function for encoding an XPCEncodable object and its message type into an xpc dictionary object
  ///
  private func encodeObject<T: XPCCodable>(_ object: T, into message: xpc_object_t) throws {
    try object.encode(into: message)
    xpc_dictionary_set_string(message, XPCMessageType, T.messageType)
  }
}

// MARK: -

extension xpc_connection_t {
  
  public func ping() async throws {
    _ = try await sendWithReply(XPCPing(), decodingReplyAs: XPCPong.self)
  }
}

// MARK: -

extension xpc_object_t {
  
  /// Returns the value of `XPC_ERROR_KEY_DESCRIPTION` as a string if it exists
  ///
  func getErrorDescription() -> String? {
    if let rawDescription = xpc_dictionary_get_string(self, XPC_ERROR_KEY_DESCRIPTION) {
      return String(cString: rawDescription)
    } else {
      return nil
    }
  }
}
