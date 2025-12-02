/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that implements common XPC event handling for web browser extensions.
*/

import XPC
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: BrowserExtension.self))

/// A base class for sharing logic between the Content, Rendering, and Networking extension types
///
open class BrowserExtension {
  
  public init() { }
  
  public func sendEndpoint(_ endpoint: xpc_endpoint_t, to connection: xpc_connection_t, replyingTo event: xpc_object_t) {
    let message = XPCEndpointMessage(endpoint: endpoint)
    do {
      try connection.send(message, replyingTo: event)
    } catch let error {
      log.error("failed to send endpoint: \(String(describing: error))")
    }
  }
  
  public func makeAnonymousEndpoint(label: String, handler: @escaping XPCConnectionEventHandler) -> xpc_endpoint_t {
    let emptyConnection = xpc_connection_create(nil, nil)
    emptyConnection.setEventHandler(label: label, handler)
    emptyConnection.activate()
    return xpc_endpoint_create(emptyConnection)
  }
}
