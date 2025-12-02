/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that communicates with the rendering extension via XPC.
*/

import Foundation
import BrowserEngineKit
import XPC
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: RenderingExtensionProxy.self))

/// The main interface for communicating with a `RenderingExtension` instance via XPC
///
public class RenderingExtensionProxy: BrowserExtensionProxy {
  
  public static let entitlementName = "com.apple.developer.web-browser-engine.rendering"
  
  public override init(connection: xpc_connection_t) {
    super.init(connection: connection)
    connection.setBooleanEntitlementRequirement(Self.entitlementName)
    connection.setEventHandler(label: "render-ext-proxy", handle(event:from:))
    connection.activate()
  }
}

// MARK: -

extension RenderingExtensionProxy {
  
  public func performWebContentExtensionHandshake(taskID: task_id_token_t) async throws -> IOSurfaceRef {
    log.log("starting extension handshake with content extension taskID \(taskID)")
    let handshake = WebContentExtensionHandshake(taskID: taskID)
    let result = try await connection.sendWithReply(handshake, decodingReplyAs: IOSurfaceMessage.self)
    return result.surface
  }
}

// MARK: -

extension RenderingExtensionProxy {
  
  public func handle(event: xpc_object_t, from connection: xpc_connection_t) {
    log.log("received event: \(String(describing: event))")
  }
}
