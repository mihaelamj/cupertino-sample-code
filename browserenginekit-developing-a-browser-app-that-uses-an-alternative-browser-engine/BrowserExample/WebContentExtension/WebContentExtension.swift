/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for a browser web content extension.
*/

import Foundation
import CustomBrowserEngine
import BrowserEngineKit
import os.log

private let log = Logger(subsystem: "WebContentExtension", category: String(describing: CustomWebContentExtension.self))

@main
class CustomWebContentExtension: BrowserExtension, WebContentExtension {
  
  /// The connection and main interface to the rendering extension.
  var renderingProxy: RenderingExtensionProxy? = nil
  
  /// The connection and main interface to the network extension.
  var networkProxy: NetworkingExtensionProxy? = nil
  
  required override init() {
    log.log("web content extension init")
    super.init()
  }
  
  /// Processes an incoming xpc connection.
  public func handle(xpcConnection: xpc_connection_t) {
    log.log("handling xpc connection: \(String(describing: xpcConnection))")
    xpcConnection.setEventHandler(label: "content-ext", handle(event:from:))
    xpcConnection.activate()
  }
  
  /// Processes an incoming xpc event.
  public func handle(event: xpc_object_t, from connection: xpc_connection_t) {
    log.log("handling xpc event: \(String(describing: event))")
    guard let rawMessageType = xpc_dictionary_get_string(event, XPCMessageType) else { return }
    let messageType = String(cString: rawMessageType)
    handleMessage(type: messageType, with: event, from: connection)
  }
  
  func handleMessage(type: String, with event: xpc_object_t, from connection: xpc_connection_t) {
    switch type {
    case BrowserExtensionTask.messageType:
      handleBrowserExtensionTask(event, from: connection)
    case WebContentExtensionBootstrapCommand.messageType:
      handleBootstrapCommand(with: event, from: connection)
    case WebContentExtensionTask.messageType:
      handleWebContentExtensionTask(event, from: connection)
    case GetXPCEndpointMessage.messageType:
      let endpoint = makeAnonymousEndpoint(label: "content-ext", handler: handle(event:from:))
      sendEndpoint(endpoint, to: connection, replyingTo: event)
    default:
      log.error("unrecognized message type: \(type)")
    }
  }
}

// MARK: - Extension Task

extension CustomWebContentExtension {
  
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

// MARK: - Bootstrap

extension CustomWebContentExtension {
  
  private func handleBootstrapCommand(with event: xpc_object_t, from connection: xpc_connection_t) {
    Task {
      do {
        log.log("decoding bootstrap command")
        let cmd = try WebContentExtensionBootstrapCommand.decode(from: event)
        try await perform(bootstrap: cmd)
        log.log("bootstrap succeded")
        try? connection.send(XPCResult.success(), replyingTo: event)
      } catch let error {
        log.error("bootstrap failed: \(String(describing: error))")
        try? connection.send(XPCResult.fail(error), replyingTo: event)
      }
    }
  }

  private func perform(bootstrap cmd: WebContentExtensionBootstrapCommand) async throws {
    log.log("performing bootstrap")
    
    if let renderingProxy = self.renderingProxy { // Connect to the rendering extension if needed.
      log.log("already connected to rendering extension: \(String(describing: renderingProxy.connection))")
    } else {
      let endpoint = cmd.renderingEndpoint
      log.log("connecting to rendering extension at: \(String(describing: endpoint))")
      let connection = xpc_connection_create_from_endpoint(endpoint)
      self.renderingProxy = .init(connection: connection)
      try await connection.ping()
      log.log("connected to rendering extension: \(String(describing: connection))")
    }
    
    if let networkProxy = self.networkProxy {  // Connect to the networking extension if needed.
      log.log("already connected to network extension: \(String(describing: networkProxy.connection))")
    } else {
      let endpoint = cmd.networkEndpoint
      log.log("connecting to network extension at: \(String(describing: endpoint))")
      let connection = xpc_connection_create_from_endpoint(endpoint)
      self.networkProxy = .init(connection: connection)
      try await connection.ping()
      log.log("connected to network extension: \(String(describing: connection))")
    }
  }
}

// MARK: - Content Extension Task

extension CustomWebContentExtension {
  
  private func handleWebContentExtensionTask(_ event: xpc_object_t, from connection: xpc_connection_t) {
    do {
      let task = try WebContentExtensionTask.decode(from: event)
      switch task {
      case .load(let destination, let pageID):
        handleLoadTask(destination: destination, pageID: pageID, event: event, from: connection)
      }
    } catch let error {
      log.error("failed to handle task: \(String(describing: error))")
    }
  }
  
  private func handleLoadTask(destination: WebViewDestination, pageID: PageID, event: xpc_object_t, from connection: xpc_connection_t) {
    Task {
      let result = try await fetchData(for: destination)
      try connection.send(result, replyingTo: event)
    }
  }
  
  /// If the destination is a local file, the web-content extension loads its contents; otherwise,
  /// ask the networking extension to fetch the remote URLs..
  private func fetchData(for destination: WebViewDestination) async throws -> NetworkTaskResult {
    switch destination {
    case .url(let url):
      log.log("loading web url \(url.absoluteString)")
      guard let networkProxy else {
        throw BrowserEngineError("not connected to the network extension")
      }
      return try await networkProxy.fetchData(from: url)
    case .htmlString(let string):
      log.log("loading string")
      guard let data = string.data(using: .utf8) else {
        throw BrowserEngineError("failed to get utf8 data from string")
      }
      return .init(response: nil, data: data, error: nil)
    case .localFile(let file):
      log.log("loading local file from \(file.absoluteString)")
      let data = try Data(contentsOf: file)
      return .init(response: nil, data: data, error: nil)
    }
  }
  
  /// Parses the network result into the string that the app displays to the user.
  private func parse(result: NetworkTaskResult) -> NSAttributedString {
    if let data = result.data {
      do {
        return try NSAttributedString(data: data, options: [
          .documentType: NSAttributedString.DocumentType.html,
          .characterEncoding: String.Encoding.utf8.rawValue
        ], documentAttributes: nil)
      } catch let error {
        return .init(string: "Failed to parse result: \(String(describing: error))")
      }
    } else if let error = result.error {
      return .init(string: String(describing: error))
    }
    return .init(string: "fatal error")
  }
}

