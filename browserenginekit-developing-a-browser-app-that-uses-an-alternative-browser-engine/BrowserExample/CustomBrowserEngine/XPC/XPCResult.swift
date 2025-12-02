/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A type that you can use to convey a result over an XPC connection.
*/

import XPC

/// A type that you can use to convey a result over an XPC connection.
public struct XPCResult: XPCCodable {
  
  public static var messageType: String = "result"
  
  private enum Key {
    static let code = "result-code"
    static let description = "result-desc"
  }
  
  public static func success(_ description: String = "") -> Self {
    return .init(description, code: 0)
  }
  
  public static func fail(_ description: String = "", code: Int = -1) -> Self {
    return .init(description, code: code)
  }
  
  public static func fail(_ error: Error, code: Int = -1) -> Self {
    return .init(error.localizedDescription, code: code)
  }
  
  public var description: String
  public var code: Int
  
  public init(_ description: String = "", code: Int) {
    self.description = description
    self.code = code
  }
  
  public func encode(into dict: xpc_object_t) throws {
    xpc_dictionary_set_int64(dict, Key.code, Int64(code))
    xpc_dictionary_set_string(dict, Key.description, description)
  }
  
  static public func decode(from dict: xpc_object_t) throws -> XPCResult {
    let code = xpc_dictionary_get_int64(dict, Key.code)
    guard let description = xpc_dictionary_get_string(dict, Key.description) else {
      throw BrowserEngineError("xpc_dictionary_get_string failed for key \(Key.description)")
    }
    return .init(String(cString: description), code: Int(code))
  }
}
