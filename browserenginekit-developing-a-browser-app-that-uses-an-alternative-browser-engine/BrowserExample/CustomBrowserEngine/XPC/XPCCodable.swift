/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Protocols to which objects conform to indicate that they can be coded and decoded as XPC objects.
*/

import Foundation
import XPC
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: XPCEncodable.self))

// MARK: -

public protocol XPCCodable: XPCEncodable, XPCDecodable {
  static var messageType: String { get }
}

// MARK: -

public protocol XPCEncodable {
  func encode(into dict: xpc_object_t) throws
}

extension XPCEncodable where Self: Codable {
  public func encode(into dict: xpc_object_t) throws {
    try XPCEncoder.encode(self, into: dict)
  }
}

// MARK: -

public protocol XPCDecodable {
  static func decode(from dict: xpc_object_t) throws -> Self
}

extension XPCDecodable where Self: Codable {
  public static func decode(from dict: xpc_object_t) throws -> Self {
    try XPCDecoder.decode(Self.self, from: dict)
  }
}

// MARK: -

public let XPCMessageType: String = "m-type"
public let XPCCodableMessageData: String = "m-data"
public let XPCCodableMessageSize: String = "m-size"

// MARK: -

struct XPCEncoder {
  
  public static let shared = XPCEncoder()
  
  public static func encode<T: Encodable>(_ item: T, into dict: xpc_object_t) throws {
    let data = try JSONEncoder().encode(item)
    let size = data.count // number of bytes
    xpc_dictionary_set_int64(dict, XPCCodableMessageSize, Int64(size))
    try data.withUnsafeBytes<Void> { unsafeBytes in
      xpc_dictionary_set_data(dict, XPCCodableMessageData, unsafeBytes, size)
    }
  }
}

struct XPCDecoder {
    
  public static func decode<T: Decodable>(_ type: T.Type, from dict: xpc_object_t) throws -> T {
    var size = Int(xpc_dictionary_get_int64(dict, XPCCodableMessageSize))
    guard let pointer = xpc_dictionary_get_data(dict, XPCCodableMessageData, &size) else {
      throw BrowserEngineError("xpc_dictionary_get_data failed for key \(XPCCodableMessageData)")
    }
    let data = Data(bytes: pointer, count: size)
    return try JSONDecoder().decode(type, from: data)
  }
}
