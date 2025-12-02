/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A remote-control protocol for streamed media.
*/

import Foundation

// An object that holds a message and serializes it to data.
class DemoMessageType {
    let params: [String: Any]

    required init(withParams msgParams: [String: Any]) {
        params = msgParams
    }

    static func createMessage<MessageType: RawRepresentable>(_ msgType: MessageType, withParams msgParams: [String: Any] = [:]) -> Self {
        var params = msgParams
        params["messageType"] = msgType.rawValue
        return Self(withParams: params)
    }

    static func fromJsonData(_ data: Data) -> Self {
        var msgParams: [String: Any] = [:]
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            msgParams = json
        } else {
            print("Invalid JSON message received: '\(String(decoding: data, as: UTF8.self))'")
        }
        return Self(withParams: msgParams)
    }

    func toJsonData() -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            print("Error: Can't convert to JSON, data: '\(params)': \(error)")
        }
        return nil
    }

    func getMessageTypeStr() -> String {
        if let strMessageType = params["messageType"] as? String {
            return strMessageType
        }
        return ""
    }

}

protocol HasMessageTypeParam {
    associatedtype MessageType
    var messageType: MessageType { get }
    func isValid() -> Bool

}

protocol DemoMessageBase: DemoMessageType, HasMessageTypeParam {
    static func create(_ msgType: MessageType, withParams msgParams: [String: Any]) -> Self
}

class DemoClientMessage: DemoMessageType, DemoMessageBase {
    enum Message: String {
        case disconnect = "DISCONNECT"
        case ping = "PING"
        case pong = "PONG"

        case connect = "CONNECT"
        case launch = "LAUNCH"
        case getStatus = "GET_STATUS"
        case setVolume = "SETVOLUME"
        case play = "PLAY"
        case stop = "STOP"
        case pause = "PAUSE"
        case unknown
    }

    static func create(_ msgType: Message, withParams msgParams: [String: Any] = [:]) -> Self {
        return createMessage(msgType, withParams: msgParams)
    }

    typealias MessageType = Message
    var messageType: MessageType {
        return Message(rawValue: getMessageTypeStr()) ?? .unknown
    }

    func isValid() -> Bool { return messageType != .unknown }

}

class DemoServerMessage: DemoMessageType, DemoMessageBase {
    enum Message: String {
        case disconnect = "DISCONNECT"
        case ping = "PING"
        case pong = "PONG"

        case status = "STATUS"
        case unknown
    }
    static func create(_ msgType: Message, withParams msgParams: [String: Any] = [:]) -> Self {
        return createMessage(msgType, withParams: msgParams)
    }
    typealias MessageType = Message
    var messageType: MessageType {
        return Message(rawValue: getMessageTypeStr()) ?? .unknown
    }
    func isValid() -> Bool { return messageType != .unknown }
}

extension DemoMessageBase {
    static func fromJson<MsgType: DemoMessageBase>(data: Data) -> MsgType {
        guard let result = fromJsonData(data) as? MsgType else {
            return MsgType(withParams: [:])
        }
        return result
    }
}
