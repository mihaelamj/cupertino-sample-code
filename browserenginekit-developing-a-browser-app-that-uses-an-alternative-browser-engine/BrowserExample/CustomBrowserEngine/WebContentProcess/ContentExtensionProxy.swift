/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that communicates with a web content extension via XPC.
*/

import Foundation
import XPC
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: WebContentExtensionProxy.self))

/// The main interface for communicating with a web content extension via XPC.
///
public class WebContentExtensionProxy: BrowserExtensionProxy {
  
  public static let entitlementName = "com.apple.developer.web-browser-engine.webcontent"
    
  public override init(connection: xpc_connection_t) {
    super.init(connection: connection)
    connection.setBooleanEntitlementRequirement(Self.entitlementName)
    connection.setEventHandler(label: "content-ext-proxy", handle(event:from:))
    connection.activate()
  }
}

// MARK: -

extension WebContentExtensionProxy {
  
  /// Sends a bootstrap command to the content extension.
  ///
  public func bootstrap(renderingExtension: xpc_endpoint_t, networkExtension: xpc_endpoint_t) async throws {
    log.log("sending content extension bootstrap command")
    let message = WebContentExtensionBootstrapCommand(renderingEndpoint: renderingExtension, networkEndpoint: networkExtension)
    let result = try await connection.sendWithReply(message, decodingReplyAs: XPCResult.self)
    if result.code != 0 { throw BrowserEngineError(result.description) }
  }
}

// MARK: -

extension WebContentExtensionProxy {
  
  /// Sends a load destination message to the content extension.
  ///
  public func load(destination: WebViewDestination, pageID: PageID) async throws -> NetworkTaskResult {
    log.log("sending load destination task with \(String(describing: destination))")
    let task: WebContentExtensionTask = .load(destination: destination, pageID: pageID)
    return try await connection.sendWithReply(task, decodingReplyAs: NetworkTaskResult.self)
  }
}

// MARK: -

extension WebContentExtensionProxy {
  
  public func handle(event: xpc_object_t, from connection: xpc_connection_t) {
    log.log("received event: \(String(describing: event))")
  }
}
