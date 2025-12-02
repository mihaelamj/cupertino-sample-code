/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that communicates with the networking extension.
*/

import Foundation
import XPC
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: NetworkingExtensionProxy.self))

/// The main interface for communicating with a `NetworkingExtension` instance via XPC.
public class NetworkingExtensionProxy: BrowserExtensionProxy {
  
  public static let entitlementName = "com.apple.developer.web-browser-engine.networking"
      
  public override init(connection: xpc_connection_t) {
    super.init(connection: connection)
    connection.setBooleanEntitlementRequirement(Self.entitlementName)
    connection.setEventHandler(label: "net-ext-proxy", handle(event:from:))
    connection.activate()
  }
}

// MARK: -

extension NetworkingExtensionProxy {
  
  /// Tells the network extension to perform a data task with the given URL.
  public func fetchData(from url: URL) async throws -> NetworkTaskResult {
    let task: NetworkExtensionTask = .data(url)
    return try await connection.sendWithReply(task, decodingReplyAs: NetworkTaskResult.self)
  }
}

// MARK: -

extension NetworkingExtensionProxy {
  
  public func handle(event: xpc_object_t, from connection: xpc_connection_t) {
    log.log("handling xpc event: \(String(describing: event))")
    guard let rawMessageType = xpc_dictionary_get_string(event, XPCMessageType) else { return }
    let messageType = String(cString: rawMessageType)
    handleMessage(type: messageType, with: event, from: connection)
  }
  
  public func handleMessage(type: String, with event: xpc_object_t, from connection: xpc_connection_t) {
    log.log("handling message: \(type)")
  }
}
