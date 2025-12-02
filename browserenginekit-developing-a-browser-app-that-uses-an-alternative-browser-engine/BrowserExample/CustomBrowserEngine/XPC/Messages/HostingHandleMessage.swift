/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A message that encapsulates a handle for a hosted layer from the rendering extension.
*/

import BrowserEngineKit

/// An XPC message type for transporting an `LayerHierarchyHandle` object
///
public struct HostingHandleMessage: XPCCodable {
  
  public static var messageType: String = "hosting-handle-message"
  
  private static let valueKey: String = "handle"
  
  public var handle: LayerHierarchyHandle
  
  public init(handle: LayerHierarchyHandle) {
    self.handle = handle
  }
  
  public func encode(into dict: xpc_object_t) throws {
    let value = handle.createXPCRepresentation()
    xpc_dictionary_set_value(dict, Self.valueKey, value)
  }
  
  public static func decode(from dict: xpc_object_t) throws -> HostingHandleMessage {
    guard let xpcValue = xpc_dictionary_get_value(dict, Self.valueKey) else {
      throw XPCError.invalidKey(Self.valueKey)
    }
    let handle = try LayerHierarchyHandle(xpcRepresentation: xpcValue)
    return .init(handle: handle)
  }
}
