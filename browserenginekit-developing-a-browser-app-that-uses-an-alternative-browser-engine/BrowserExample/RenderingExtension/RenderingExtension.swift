/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for the browser's rendering extension.
*/

import Foundation
import os.log
import CustomBrowserEngine
import BrowserEngineKit

private let log = Logger(subsystem: "RenderingExtension", category: String(describing: CustomRenderingExtension.self))

@main
class CustomRenderingExtension: BrowserExtension, RenderingExtension {
  
  private var layerHierarchies: [PageID: LayerHierarchy] = [:]
    
  required override init() {
    log.log("rendering extension init")
    super.init()
  }
  
  /// Processes an incoming xpc connection.
  public func handle(xpcConnection: xpc_connection_t) {
    log.log("handling xpc connection: \(String(describing: xpcConnection))")
    xpcConnection.setEventHandler(label: "render-ext", handle(event:from:))
    xpcConnection.activate()
  }
  
  /// Processes an incoming xpc event.
  public func handle(event: xpc_object_t, from connection: xpc_connection_t) {
    log.log("handling xpc event: \(String(describing: event))")
    guard let rawMessageType = xpc_dictionary_get_string(event, XPCMessageType) else { return }
    let messageType = String(cString: rawMessageType)
    handleMessage(type: messageType, with: event, from: connection)
  }
  
  private func handleMessage(type: String, with event: xpc_object_t, from connection: xpc_connection_t) {
    switch type {
    case BrowserExtensionTask.messageType:
      handleBrowserExtensionTask(event, from: connection)
    case RenderingExtensionTask.messageType:
      handleRenderingExtensionTask(event, from: connection)
    case WebContentExtensionHandshake.messageType:
      handleWebContentExtensionHandshake(event, from: connection)
    case GetXPCEndpointMessage.messageType:
      let endpoint = makeAnonymousEndpoint(label: "render-ext", handler: handle(event:from:))
      sendEndpoint(endpoint, to: connection, replyingTo: event)
    default:
      log.error("unrecognized message type: \(type)")
    }
  }
}

// MARK: - Extension Task

extension CustomRenderingExtension {
  
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

// MARK: - Handshake

extension CustomRenderingExtension {
  
  private func handleRenderingExtensionTask(_ event: xpc_object_t, from connection: xpc_connection_t) {
    do {
      let task = try RenderingExtensionTask.decode(from: event)
      switch task {
      case .makeHostingHandle(let pageID):
        makeHostingLayer(id: pageID, with: event, from: connection)
      }
    } catch let error {
      log.error("failed to handle RenderingTaskType: \(String(describing: error))")
    }
  }
  
  func handleWebContentExtensionHandshake(_ event: xpc_object_t, from connection: xpc_connection_t) {
    do {
      let handshake = try WebContentExtensionHandshake.decode(from: event)
      log.log("received content extension handshake from \(String(describing: connection)) with \(String(describing: handshake.taskID))")
    } catch let error {
      log.error("failed to handle content process handshake: \(String(describing: error))")
    }
  }
}

// MARK: Layer Hosting

extension CustomRenderingExtension {
  
  func makeHostingLayer(id: PageID, with event: xpc_object_t, from connection: xpc_connection_t) {
    Task { @MainActor in
      do {
        let hostable = try getOrMakeHostable(id: id)
        let message = HostingHandleMessage(handle: hostable.handle)
        try connection.send(message, replyingTo: event)
      } catch let error {
        log.error("failed to create hosting layer: \(String(describing: error))")
      }
    }
  }
  
  @MainActor
  public func getOrMakeHostable(id: PageID) throws -> LayerHierarchy {
    if let hostable = layerHierarchies[id] {
      return hostable
    } else {
      let hostable = try LayerHierarchy()
      layerHierarchies[id] = hostable
      return hostable
    }
  }
}
