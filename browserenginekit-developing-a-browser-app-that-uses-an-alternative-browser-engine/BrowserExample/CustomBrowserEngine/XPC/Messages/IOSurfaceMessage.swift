/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A message that encapsulates an IOSurfaceRef from the rendering extension.
*/

import IOSurface

/// A codable type for sending IOSurfaces over process boundaries.
///
public struct IOSurfaceMessage: XPCCodable {
  
  public static var messageType: String = "iosurface-message"

  private static let key: String = "iosurface"
  
  public var surface: IOSurfaceRef
  
  public init(surface: IOSurfaceRef) {
    self.surface = surface
  }
  
  public func encode(into dict: xpc_object_t) throws {
    let port = IOSurfaceCreateMachPort(surface)
    xpc_dictionary_set_mach_send(dict, Self.key, port)
  }
  
  public static func decode(from dict: xpc_object_t) throws -> IOSurfaceMessage {
    let port = xpc_dictionary_copy_mach_send(dict, Self.key)
    guard let surface = IOSurfaceLookupFromMachPort(port) else {
      throw BrowserEngineError("IOSurfaceLookupFromMachPort(\(String(describing: port))) failed")
    }
    return .init(surface: surface)
  }
}
