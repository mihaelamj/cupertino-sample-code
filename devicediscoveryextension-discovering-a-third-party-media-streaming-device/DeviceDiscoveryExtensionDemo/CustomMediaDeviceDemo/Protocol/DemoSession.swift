/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The protocol session layer for a client or server.
*/

import Foundation
import os

let hearbeatPeriodMs = 500
let hearbeatRestTimeMs = 2500 // 2s period relaxed beats
let heartbeatDisconnectMs = 4000 // 4s timeout
let hearbeatDisconnectCount = heartbeatDisconnectMs / hearbeatPeriodMs
let hearbeatRestCount = hearbeatRestTimeMs / hearbeatPeriodMs

enum DemoProtocolError: Error {
    case invalidMessageParams
    case invalidConnection
    case genericError(message: String)
}

struct DemoServerStatus {
    struct Volume {
        var muted = false
        var level: Float = 1.0
    }
    var volume = Volume()
    struct State {
        var url = ""
        var playing = false
        var timeRemaining: Float = 0.0
        var sessionId: Int = -1
    }
    var state = State()
}

enum DemoSessionState {
    case disconnected
    case disconnecting
    case connecting
    case connected

    func toStr() -> String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        case .disconnecting:
            return "Disconnecting"
        }
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: DemoSessionState) {
        appendLiteral(value.toStr())
    }
}

class DemoSession<TxMsgT: DemoMessageBase, RxMsgT: DemoMessageBase>: DemoConnectionDelegate {
    var logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "DemoSession")
    typealias DemoConnectionType = DemoUdpConnection
    typealias TxMessageType = TxMsgT
    typealias RxMessageType = RxMsgT

    var peerConnection: DemoConnectionType?
    var currentState: DemoSessionState = .disconnected
    private var instanceServerStatus = DemoServerStatus()
    var serverStatus: DemoServerStatus {
        get { instanceServerStatus }
        set {
            instanceServerStatus = newValue
            updateServerState()
        }
    }

    // MARK: DemoConnectionDelegate
    func didStart(connection: DemoConnection) {
        peerConnection = connection as? DemoConnectionType
        guard peerConnection != nil else {
            logger.log("unexpected incoming connection type for \(String(describing: self.peerConnection))")
            connection.stop()
            return
        }

        logger.log("\(String(describing: connection)) didStart")
        guard tryStateChange(from: .disconnected, to: .connecting) ||
            tryStateChange(from: .connecting, to: .connected)
        else {
            logger.log("DemoSession, invalid state for \(String(describing: self.peerConnection))")
            connection.stop()
            return
        }
    }

    func didStop(connection: DemoConnection, error: Error?) {
        logger.log("\(String(describing: connection)) stopped")
        guard tryStateChange(from: currentState, to: .disconnected) else {
            return
        }
        if peerConnection === (connection as? DemoConnectionType) {
            peerConnection = nil
        } else {
            logger.error("\(String(describing: connection)) wasn't active")
        }
    }

    func didSend(error: Error?) {
        if let anError = error {
            logger.error("Got error while sending data: \(String(describing: anError))")
        }
    }

    func didReceive(data: Data, connection: DemoConnection, error: Error?) {
        guard error == nil else {
            logger.log("Received data with errror '\(String(describing: error))' from \(String(describing: connection)). Ignoring.")
            return
        }
        if !isCurrentConnection(connection) {
            peerConnection = connection as? DemoConnectionType
        }
        let message: RxMessageType = RxMessageType.fromJson(data: data)
        guard message.isValid() else {
            logger.log("received invalid message: '\(String(decoding: data, as: UTF8.self))'")
                return
        }
	heartbeatOk()
        didReceive(message: message)
    }

	// MARK: Session
	func post(message: TxMessageType) throws {
		guard peerConnection != nil else {
			logger.error("Can't send \(message.getMessageTypeStr()) due invalid connection")
			throw DemoProtocolError.invalidConnection
		}
		if let jsonObject = message.toJsonData() {
			logger.debug("Sending \(String(decoding: jsonObject, as: UTF8.self))")
			peerConnection?.send(data: jsonObject)
		} else {
			logger.error("Can't convert \(message.getMessageTypeStr()) message to JSON")
			throw DemoProtocolError.invalidMessageParams
		}
	}

	func stop() {
		if tryStateChange(from: .connected, to: .disconnecting) ||
			tryStateChange(from: .connecting, to: .disconnecting) {
			logger.log("Stopping.")
		}
		if let timer = heartbeatTimer {
			heartbeatTimer = nil
			timer.invalidate()
			logger.log("Connection hearbeat cancelled")
		}
		guard let connection = peerConnection else {
			logger.error("Can't stop empty connection.")
			return
		}
		logger.log("stopping '\(String(describing: connection))'")
		connection.stop()
	}

    func tryStateChange(from oldState: DemoSessionState, to newState: DemoSessionState) -> Bool {
        if currentState == oldState {
            currentState = newState
            didStateChange(from: oldState, to: newState)
            return true
        }
        return false
    }

    private func getStateStr(_ astate: DemoSessionState) -> String {
        astate.toStr()
    }

    func didReceive(message: RxMessageType) {
        logger.warning("message ignored: \(message.getMessageTypeStr())")
    }

    func isCurrentConnection(_ connection: DemoConnection) -> Bool {
        return peerConnection != nil && peerConnection === connection as? DemoConnectionType
    }

    public var stateUpdatedHandler: ((_ state: DemoSessionState) -> Void)?
    func didStateChange(from oldState: DemoSessionState, to newState: DemoSessionState) {
        logger.log("State change, from: \(self.getStateStr(oldState)), to: \(self.getStateStr(newState))")
        if let stateHandler = stateUpdatedHandler {
            stateHandler(newState)
        }
    }

    public var serverUpdateHandler: ((_ serverState: DemoServerStatus) -> Void)?
    func updateServerState() {
        if let handler = serverUpdateHandler {
            handler(serverStatus)
        }
    }

    func getConnection() -> DemoConnectionType? {
        return peerConnection
    }

	var heartbeatTimer: Timer?
	var hearbeatCount: Int = 0

	func setupHeartbeat() {
		guard heartbeatTimer == nil else {
			logger.warning("connection heartbeat already started")
			return
		}
		heartbeatTimer = Timer.scheduledTimer(withTimeInterval: Double(hearbeatPeriodMs) * 0.001, repeats: true) { [self] _ in
			hearbeatCount += 1
			if hearbeatCount <= hearbeatRestCount {
				return
			}
			if hearbeatCount >= hearbeatDisconnectCount {
				logger.log("Hearbeat disconnect count reached, disconnecting.")
				stop()
			} else {
				didHeartbeatMiss()
			}
		}
	}

	func didHeartbeatMiss() {
	}

	func heartbeatOk() {
		hearbeatCount = 0
	}

}

class DemoClientSession: DemoSession<DemoClientMessage, DemoServerMessage> {
    var remoteServerStatus = DemoServerStatus() // The per-client connection.

    override init() {
        super.init()
        logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "DemoClientSession")
    }

    override func didStart(connection: DemoConnection) {
        super.didStart(connection: connection)
        guard isCurrentConnection(connection) else {
            return
        }
        logger.log("New session started from '\(String(describing: self.peerConnection)) ")
        do {
            try post(message: DemoClientMessage.create(.connect))
        } catch {
            logger.error("Can't send connect message")
        }
    }
    override func didReceive(message: RxMessageType) {
        if tryStateChange(from: .connecting, to: .connected) {
            logger.log("Connection completed using message \(message.getMessageTypeStr())")
        }
        switch message.messageType {
        case .disconnect:
            stop()
        case .ping:
            try? post(message: TxMessageType.create(.pong))
		case .pong:
			logger.debug("PONG")
        case .status:
            logger.log("Got remote status:")
            if let status = message.params["STATUS"] as? [String: Any] {
                var newStatus = serverStatus
                if let volume = status["VOLUME"] as? [String: Any] {
                    if let muted = volume["MUTED"] as? Bool {
                        newStatus.volume.muted = muted
                    }
                    if let level = volume["LEVEL"] as? Float {
                        newStatus.volume.level = level
                    }
                    logger.log("  Volume: \(newStatus.volume.muted ? "is" : "not") muted, level=\(self.serverStatus.volume.level)" )
                }
                if let state = status["STATE"] as? [String: Any] {
                    if let url = state["URL"] as? String {
                        newStatus.state.url = url
                    }
                    if let playing = state["PLAYING"] as? Bool {
                        newStatus.state.playing = playing
                    }
                    if let timeRemaining = state["TIME_REMAINING"] as? Float {
                        newStatus.state.timeRemaining = timeRemaining
                    }
                    if let sessionId = state["SESSIONID"] as? Int {
                        newStatus.state.sessionId = sessionId
                    }
                    logger.log("""
                          State: url='\(newStatus.state.url)', \
                        playing=\(newStatus.state.playing ? "Y" : "N"), \
                        timeRemaining=\(newStatus.state.timeRemaining), \
                        sessionId=\(newStatus.state.sessionId)
                        """)

                }
                serverStatus = newStatus
            }
        default:
            logger.warning("message ignored: \(message.getMessageTypeStr())")
        }
    }

	override func didStateChange(from oldState: DemoSessionState, to newState: DemoSessionState) {
		super.didStateChange(from: oldState, to: newState)
		if newState == .connecting {
			setupHeartbeat()
		}
	}

	override func didHeartbeatMiss() {
		switch currentState {
		case .connected:
			try? post(message: TxMessageType.create(.ping))
		case .connecting:
			try? post(message: TxMessageType.create(.connect))
		default:
			break
		}
	}

    // MARK: remote control
    func sendPlay() {
        try? post(message: TxMessageType.create(.play))
    }
    func sendStop() {
        try? post(message: TxMessageType.create(.stop))
    }
}

class DemoServerSession: DemoSession<DemoServerMessage, DemoClientMessage> {
    private static var sharedServerStatus = DemoServerStatus()
    override var serverStatus: DemoServerStatus {
        get { DemoServerSession.sharedServerStatus }
        set {
            DemoServerSession.sharedServerStatus = newValue
            updateServerState()
            sendStatus()
        }
    }

    override init() {
        super.init()
        logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "DemoServerSession")
    }

    override func didStart(connection: DemoConnection) {
        super.didStart(connection: connection)
        guard isCurrentConnection(connection) else {
            return
        }
        logger.log("New session started from '\(String(describing: self.peerConnection)) ")

    }

	override func didReceive(message: RxMessageType) {
		switch message.messageType {
		case .connect:
			logger.log("Connect, received")
			if tryStateChange(from: .disconnected, to: .connecting) /* didStart() expected */
					|| tryStateChange(from: .connecting, to: .connected) /* didStart() happened */ {
				logger.log("Connect ignored")
			}
		case .disconnect:
			stop()

		case .ping:
			try? post(message: TxMessageType.create(.pong))

		case .pong:
			logger.debug("PONG")

		case .play:
			serverStatus.state.playing = true

		case .stop:
			var newStatus = serverStatus
			newStatus.state.playing = false
			newStatus.state.url = ""
			serverStatus = newStatus

		case .pause:
			serverStatus.state.playing = false

		default:
			logger.log("DemoServerSession, message ignored: \(message.getMessageTypeStr())")
		}
	}

	override func didStateChange(from oldState: DemoSessionState, to newState: DemoSessionState) {
		super.didStateChange(from: oldState, to: newState)
		if newState == .connected {
			sendStatus()
		}
	}

    func sendStatus() {
        guard currentState == .connected else {
            return
        }
        let statusMsg = TxMessageType.create(.status, withParams: ["STATUS": getStatus()])
        try? post(message: statusMsg)
    }

    private func getStatus() -> [String: Any] {
        return [
            "VOLUME": getVolume(),
            "STATE": getState()
        ]
    }

    private func getVolume() -> [String: Any] {
        return [
            "MUTED": serverStatus.volume.muted,
            "LEVEL": serverStatus.volume.level
        ]
    }

    private func getState() -> [String: Any] {
        return [
            "URL": serverStatus.state.url,
            "PLAYING": serverStatus.state.playing,
            "TIME_REMAINING": serverStatus.state.timeRemaining,
            "SESSIONID": serverStatus.state.sessionId
        ]
    }

}

extension DemoClientSession: CustomStringConvertible {
    var description: String {
        if let connection = getConnection() {
            return "DemoClientSession connectionId=\(connection.connectionId)"
        } else {
            return "DemoClientSession (empty connection)"
        }
    }
}

extension DemoServerSession: CustomStringConvertible {
    var description: String {
        if let connection = getConnection() {
            return "DemoServerSession connectionId=\(connection.connectionId)"
        } else {
            return "DemoServerSession (empty connection)"
        }
    }
}
