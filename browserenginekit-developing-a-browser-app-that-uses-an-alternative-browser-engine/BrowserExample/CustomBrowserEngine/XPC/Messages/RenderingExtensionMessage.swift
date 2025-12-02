/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Messages that the browser app sends to, and receives from, its rendering extension.
*/

import XPC
import Foundation

public enum RenderingExtensionTask: Codable, XPCCodable {
  public static let messageType: String = "render-ext-task"
  case makeHostingHandle(id: PageID)
}

// MARK: -

public struct WebContentExtensionHandshake: XPCCodable {
  
  public static let messageType: String = "render-content-ext-handshake"
  public static let taskIDKey: String = "task-id"
  
  public var taskID: task_id_token_t
  
  public func encode(into dict: xpc_object_t) throws {
    xpc_dictionary_set_mach_send(dict, Self.taskIDKey, taskID)
  }
  
  public static func decode(from dict: xpc_object_t) throws -> WebContentExtensionHandshake {
    let taskID = xpc_dictionary_copy_mach_send(dict, Self.taskIDKey)
    return .init(taskID: taskID)
  }
}
