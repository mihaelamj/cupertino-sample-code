/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for the browser's networking extension.
*/

import Foundation
import BrowserEngineKit
import CustomBrowserEngine
import os.log

private let log = Logger(subsystem: "NetworkingExtension", category: String(describing: CustomNetworkingExtension.self))

@main
class CustomNetworkingExtension: BrowserExtension, NetworkingExtension {
  
  private let networkManager = NetworkSession()

  required override init() {
    log.log("networking extension init")
    super.init()
  }

  /// Processes an incoming xpc connection.
  public func handle(xpcConnection: xpc_connection_t) {
    log.log("handling xpc connection: \(String(describing: xpcConnection))")
    xpcConnection.setEventHandler(label: "net-ext", handle(event:from:))
    xpcConnection.activate()
  }
  
  /// Processes an incoming xpc event.
  public func handle(event: xpc_object_t, from connection: xpc_connection_t) {
    log.log("handling xpc event: \(String(describing: event))")
    guard let rawMessageType = xpc_dictionary_get_string(event, XPCMessageType) else { return }
    let messageType = String(cString: rawMessageType)
    handleMessage(type: messageType, with: event, from: connection)
  }
  
  public func handleMessage(type: String, with event: xpc_object_t, from connection: xpc_connection_t) {
    log.log("handling message: \(type)")
    switch type {
    case BrowserExtensionTask.messageType:
      handleBrowserExtensionTask(event, from: connection)
    case NetworkExtensionTask.messageType:
      handleNetworkExtensionTask(event, from: connection)
    case GetXPCEndpointMessage.messageType:
      let endpoint = makeAnonymousEndpoint(label: "net-ext", handler: handle(event:from:))
      sendEndpoint(endpoint, to: connection, replyingTo: event)
    default:
      log.error("unrecognized message type: \(type)")
    }
  }
}

// MARK: - Extension Task

extension CustomNetworkingExtension {
  
  private func handleBrowserExtensionTask(_ event: xpc_object_t, from connection: xpc_connection_t) {
    do {
      let task = try BrowserExtensionTask.decode(from: event)
      switch task {
      case .applyRestrictedSandbox(let int):
        applyRestrictedSandbox(int)
      }
    } catch let error {
      log.error("failed to handle BrowserExtensionTask from \(String(describing: connection)): \(String(describing: error))")
    }
  }
  
  private func applyRestrictedSandbox(_ int: Int) {
    switch int {
    case 1:
      let revision = RestrictedSandboxRevision.revision1
      log.log("applying restricted sandbox with revision \(String(describing: revision))")
      applyRestrictedSandbox(revision: revision)
    default:
      log.error("failed to apply restricted sandbox with revision \(int)")
    }
  }
}

// MARK: - Networking Extension Task

extension CustomNetworkingExtension {
  
  private func handleNetworkExtensionTask(_ event: xpc_object_t, from connection: xpc_connection_t) {
    do {
      let task = try NetworkExtensionTask.decode(from: event)
      networkManager.perform(task: task, with: event, for: connection)
    } catch let error {
      log.error("failed to handle network extension task: \(String(describing: error))")
    }
  }
}
