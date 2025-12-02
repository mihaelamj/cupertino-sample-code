/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that communicates with browser extension processes via XPC.
*/

import Foundation
import XPC
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: BrowserExtensionProxy.self))

public enum BrowserExtensionTask: Codable, XPCCodable {
  public static let messageType: String = "ext-task"
  case applyRestrictedSandbox(version: Int)
}

// MARK: -

/// The base interface class for communicating with a `BrowserExtension` instance via XPC.
///
public class BrowserExtensionProxy {
  
  public var connection: xpc_connection_t
  
  public init(connection: xpc_connection_t) {
    self.connection = connection
  }
  
  /// Sends a ping to the extension and waits for a pong reply.
  public func ping() async throws {
    _ = try await connection.sendWithReply(XPCPing(), decodingReplyAs: XPCPong.self)
  }
}

// MARK: -

extension BrowserExtensionProxy {
  
  func getEndpoint() async throws -> xpc_endpoint_t {
    let cmd = GetXPCEndpointMessage()
    let reply = try await connection.sendWithReply(cmd, decodingReplyAs: XPCEndpointMessage.self)
    return reply.endpoint
  }
  
  func applyRestrictedSandbox(version: Int) throws {
    let message = BrowserExtensionTask.applyRestrictedSandbox(version: version)
    try connection.send(message)
  }
}
