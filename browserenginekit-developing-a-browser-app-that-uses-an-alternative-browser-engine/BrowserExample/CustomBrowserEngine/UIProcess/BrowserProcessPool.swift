/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages the browser's extension processes.
*/

import BrowserEngineKit
import UIKit
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: BrowserProcessPool.self))

public typealias BrowserExtensionID = pid_t

public protocol ServiceProvider {
  var webContentServiceID: String { get }
  var renderingServiceID: String { get }
  var networkServiceID: String { get }
}

// MARK: -

/// Manages the web-content, rendering, and networking processes on the system.
public class BrowserProcessPool {
  
  public static let shared: BrowserProcessPool = .init()
  
  private let lockdownVersion: Int = 1
  
  private(set) var renderingProcessRuntimeGrant: ProcessCapability.Grant? = nil
  
  private(set) var renderingProcess: RenderingProcess? = nil
  
  private(set) var networkProcessRuntimeGrant: ProcessCapability.Grant? = nil
  
  private(set) var networkProcess: NetworkingProcess? = nil
  
  private(set) var webContentProcesses: [PageID: WebContentProcess] = [:]
  
  private(set) var webContentRuntimeGrants: [PageID: ProcessCapability.Grant] = [:]
  
  /// Launches the required processes for a new `WebView` and orchestrates the bootstrap process.
  public func launchProcesses(id: PageID) async throws -> WebContentExtensionProxy {
    
    // 1. Launch a new web content process instance.
    let contentProcess = try await getOrLaunchContentProcess(pageID: id)
    let contentConnection = try contentProcess.makeLibXPCConnection()
    let contentProxy = WebContentExtensionProxy(connection: contentConnection)
    try contentProxy.applyRestrictedSandbox(version: lockdownVersion)
    
    // 2. Get the shared rendering process.
    let renderingProcess = try await getOrLaunchRenderingProcess()
    let renderingConnection = try renderingProcess.makeLibXPCConnection()
    let renderingProxy = RenderingExtensionProxy(connection: renderingConnection)
    let renderingEndpoint = try await renderingProxy.getEndpoint()
    try renderingProxy.applyRestrictedSandbox(version: lockdownVersion)
    
    // 3. Get the shared networking process.
    let networkProcess = try await getOrLaunchNetworkProcess()
    let networkConnection = try networkProcess.makeLibXPCConnection()
    let networkProxy = NetworkingExtensionProxy(connection: networkConnection)
    let networkEndpoint = try await networkProxy.getEndpoint()
    try networkProxy.applyRestrictedSandbox(version: lockdownVersion)
    
    // 4. Perform the bootstrap process.
    try await contentProxy.bootstrap(renderingExtension: renderingEndpoint, networkExtension: networkEndpoint)
    
    webContentProcesses[id] = contentProcess
    return contentProxy
  }
  
  /// Applies a capability to the content process for a given page ID.
  public func grantCapability(_ capability: ProcessCapability, pageID: PageID) {
    guard let process = webContentProcesses[pageID] else { return }
    if let grant = webContentRuntimeGrants.removeValue(forKey: pageID) {
      grant.invalidate()
    }
    do {
      log.log("granting process capability: \(String(describing: capability))")
      webContentRuntimeGrants[pageID] = try process.grantCapability(capability)
    } catch let error {
      log.error("failed to grant capability to content process: \(String(describing: error))")
    }
  }
}

// MARK: -

extension BrowserProcessPool {
  
  public func getContentProcessViewInteraction(id: PageID) -> UIInteraction? {
    return webContentProcesses[id]?.createVisibilityPropagationInteraction()
  }
  
  public func getRenderingProcessViewInteraction() -> UIInteraction? {
    return renderingProcess?.createVisibilityPropagationInteraction()
  }
}

// MARK: -

extension BrowserProcessPool {
  
  /// If a web-content extension is not already running for the given pageID, this launches it.
  public func getOrLaunchContentProcess(pageID: PageID) async throws -> WebContentProcess {
    if let contentProcess = webContentProcesses[pageID] { return contentProcess }
    let process = try await WebContentProcess {
      log.log("content process was interrupted (pageID: \(pageID))")
      self.onContentProcessInterrupt(id: pageID)
    }
    log.log("launched WebContent process \(String(describing: process))")
    self.webContentProcesses[pageID] = process
    webContentRuntimeGrants[pageID] = try process.grantCapability(.foreground)
    return process
  }
  
  /// If the rendering extension is not already running, this launches it.
  public func getOrLaunchRenderingProcess() async throws -> RenderingProcess {
    if let renderingProcess { return renderingProcess }
    let process = try await RenderingProcess {
      log.log("rendering process was interrupted")
      self.onRenderingProcessInterrupt()
    }
    log.log("launched Rendering process \(String(describing: process))")
    self.renderingProcess = process
    renderingProcessRuntimeGrant = try process.grantCapability(.foreground)
    return process
  }
  
  /// If the networking extension is not already running, this launches it.
  public func getOrLaunchNetworkProcess() async throws -> NetworkingProcess {
    if let networkProcess { return networkProcess }
    let process = try await NetworkingProcess {
      log.log("network process was interrupted")
      self.onNetworkProcessInterrupt()
    }
    log.log("launched Networking process \(String(describing: process))")
    self.networkProcess = process
    networkProcessRuntimeGrant = try process.grantCapability(.foreground)
    return process
  }
}

// MARK: -

extension BrowserProcessPool {
  
  /// Invalidates the rendering process and its runtime grant.
  private func onRenderingProcessInterrupt() {
    renderingProcess?.invalidate()
    renderingProcess = nil
    renderingProcessRuntimeGrant?.invalidate()
    renderingProcessRuntimeGrant = nil
  }
  
  /// Invalidates the networking process and its runtime grant.
  private func onNetworkProcessInterrupt() {
    networkProcess?.invalidate()
    networkProcess = nil
    networkProcessRuntimeGrant?.invalidate()
    networkProcessRuntimeGrant = nil
  }
  
  /// Invalidates the web-content process for the given page ID, and its runtime grant.
  private func onContentProcessInterrupt(id: PageID) {
    self.invalidateContentProcess(for: id)
  }
  
  public func invalidateContentProcess(for id: PageID) {
    if let process = webContentProcesses.removeValue(forKey: id) {
      process.invalidate()
    }
    if let grant = webContentRuntimeGrants.removeValue(forKey: id) {
      grant.invalidate()
    }
  }
}

