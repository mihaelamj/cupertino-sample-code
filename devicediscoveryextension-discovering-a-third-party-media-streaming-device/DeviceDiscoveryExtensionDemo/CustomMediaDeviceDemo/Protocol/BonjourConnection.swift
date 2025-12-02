/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities that facilitate a connection between a client and server.
*/

import Foundation
import Network
import os

protocol DemoConnection {
    func start()
    func send(data: Data)
    func stop()
    var connectionId: Int { get }
}

// An interface to announce important connection events.
protocol DemoConnectionDelegate: AnyObject {
    
    // Indicates that the connection is ready to send and receive.
    func didStart(connection: DemoConnection)
    
    // Indicates when the connection fails or the user cancels it.
    func didStop(connection: DemoConnection, error: Error?)
    func didSend(error: Error?)
    
    // Indicates when the connection receives an initial message.
    func didReceive(data: Data, connection: DemoConnection, error: Error?)
}

class DemoUdpConnection: DemoConnection {
    var connectionId: Int

	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "BonjourConnection")

	private static var nextID: Int = 0
	let  connection: NWConnection
	private var isCancelled = false
	private var isFailed = false

    // An object that reacts to important connection events.
    // Set this property before starting the connection.
    weak var delegate: DemoConnectionDelegate?

	init(nwConnection: NWConnection) {
		connection = nwConnection
		connectionId = Self.nextID
		Self.nextID += 1
	}

	func start() {
		logger.log("connection \(self.connectionId) will start")
		connection.stateUpdateHandler = self.stateDidChange(to:)
		setupReceive()
		connection.start(queue: .main)
	}

	private func setupReceive() {
		connection.receiveMessage() { [self] (data, _, _, error) in
			if isCancelled || isFailed {
				logger.log("stopping receiveMessage as the connection was cancelled or failed")
				return
			}
			if let data = data, !data.isEmpty {
				let message = String(data: data, encoding: .utf8)
				logger.debug("connection \(self.connectionId) did receive, data: \(data as NSData) string: \(message ?? "-")")
				delegate?.didReceive(data: data, connection: self, error: error)
			}
			setupReceive()
		}
	}

    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            logger.log("connection \(self.connectionId) in waiting state, error='\(String(describing: error))'")
        case .ready:
            logger.log("connection \(self.connectionId) ready")
            if let connectionDelegate = delegate {
                connectionDelegate.didStart(connection: self)
            } else {
                logger.warning("No connection delegate set")
            }
        case .failed(let error):
			isFailed = true
            logger.error("Failed connection error='\(String(describing: error))'")
            delegate?.didStop(connection: self, error: error)
        case .cancelled:
			logger.error("Cancelled connection by \(self.isCancelled ? "Local" : "Remote")")
			isCancelled = true
            delegate?.didStop(connection: self, error: nil)
        default:
            logger.error("Connection state updated to'\(String(describing: state))'")
        }
    }

	func send(data: Data) {
		connection.send(content: data, completion: .contentProcessed({ [self] error in
			if let error = error {
				delegate?.didSend(error: error)
				return
			}
			logger.debug("connection \(self.connectionId) did send, data: \(data as NSData)")
			delegate?.didSend(error: nil)
		}))
	}

	func stop() {
		guard !isCancelled else {
			logger.debug("connection \(self.connectionId) already stopped")
			return
		}
		logger.log("connection \(self.connectionId) will stop")
		stop(error: nil)
	}

	private func stop(error: Error?) {
		isCancelled = true
		connection.cancel()
	}
}
