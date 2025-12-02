/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A networking server for a Bonjour service.
*/

import Network
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import os

func getDeviceUniqueId() -> String {
	struct Cached {
		static var uniqueId: String {
            // Match the advertised length limit of the Bluetooth device.
			let sharedDeviceIdLength = 8
			var hasher = Hasher()
	#if os(macOS)
			var deviceId = Host.current().name ?? UUID().uuidString
			let targetService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

			if targetService != 0 {
				let serialNumberKeyRef = kIOPlatformSerialNumberKey as CFString
				let serialNumberRef = IORegistryEntryCreateCFProperty(targetService, serialNumberKeyRef, kCFAllocatorDefault, 0).takeUnretainedValue()
				IOObjectRelease(targetService)

				if let serialNumber = serialNumberRef as? String {
					deviceId = serialNumber
				}
			}
	#else
            // Use a random device identifier.
			let deviceId = UIDevice.current.identifierForVendor ?? UUID()
	#endif
			hasher.combine(deviceId)
			let hashValue = hasher.finalize()
			let data = withUnsafeBytes(of: hashValue) { Data($0) }
			return String(data.base64EncodedString().prefix(sharedDeviceIdLength))
		}
	}
	return Cached.uniqueId
}

class BonjourServer: NSObject, ObservableObject {
	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "BonjourServer")

	let deviceId = getDeviceUniqueId()
	var listener: NWListener? = nil
	@Published var isRunning = false
	private var isActive = false
	
	private var connectionsByID: [Int: (connection: DemoConnection, session: DemoServerSession)] = [:]
	private var deviceName = "DemoAppDevice"
    // The protocol that the sample app sets by default.
	private var targetProtocol = "Ladybug"
	
	func setupListener() {
		logger.log("Setup network listener for device '\(self.deviceId)'")
		let txtDict = [
			"ID": deviceId.data(using: .utf8)!,
			"NAME": deviceName.data(using: .utf8)!,
			"PROTO": targetProtocol.data(using: .utf8)!
		]
		logger.log("ID Checker: Setting Bonjour txt: '\(txtDict)'")
		let txtData = NetService.data(fromTXTRecord: txtDict)

		listener = try! NWListener(using: .udp)
		listener!.service = NWListener.Service(name: "DD demo server", type: "_deviceaccess._udp.", domain: nil, txtRecord: txtData)
	}

	deinit {
		invalidate()
	}
	
	func activate(name: String, withProtocol proto: String) throws {
		if !isActive {
			isActive = true
			logger.log("\(name) Server starting...")
			deviceName = name
			targetProtocol = proto
			setupListener()
			listener!.stateUpdateHandler = self.stateDidChange(to:)
			listener!.newConnectionHandler = self.didAccept(nwConnection:)
			listener!.start(queue: .main)
		}
	}
	
	func invalidate() {
		if isActive {
			isActive = false
			logger.log("Server stopping...")
			listener!.stateUpdateHandler = nil
			listener!.newConnectionHandler = nil
			listener!.cancel()
			for (connection, _) in connectionsByID.values {
				logger.log("server closing \(String(describing: connection))")
				connection.stop()
			}
			connectionsByID.removeAll()
			listener = nil
		}
	}
	
	func stateDidChange(to newState: NWListener.State) {
		logger.log("New server state: \(newState)")
		switch newState {
		case .ready:
			isRunning = true
		case .failed(let error):
			logger.log("Server failure, error: \(error.localizedDescription)")
			isRunning = false
			invalidate()
		default:
			isRunning = false
		}
	}
	
	private func didAccept(nwConnection: NWConnection) {
		let connection = DemoUdpConnection(nwConnection: nwConnection)
        let session = DemoServerSession()
        session.stateUpdatedHandler = { [self, session] (state: DemoSessionState) in
            switch state {
            case .connected:
                logger.log("Client session connected \(session)")
            case .disconnected:
                logger.error("Client session disconnected: \(session)")
                if let peerConnection = session.getConnection() {
                    connectionsByID.removeValue(forKey: peerConnection.connectionId)
                }
            default:
                break
            }
        }
        session.serverUpdateHandler = didServerStateUpdate
        connection.delegate = session
        // The session’s delegate manages the connection and uses it when invalidating the server.
        connectionsByID[connection.connectionId] = (connection: connection, session: session)
		connection.start() // Start the connection.
		logger.log("server accepted connection with Id \(connection.connectionId)")
	}
    var updateServerStateHandler: ((DemoServerStatus) -> Void)?
    private func didServerStateUpdate(_ serverState: DemoServerStatus) {
        if let handler = updateServerStateHandler {
            handler(serverState)
        }
    }
}

extension NWListener.State: CustomStringConvertible {
	public var description: String {
		switch self {
		case .cancelled:
			return ".cancelled"
		case .failed(let error):
			return ".failed (\(error.debugDescription))"
		case .ready:
			return ".ready"
		case .waiting(let error):
			return ".waiting (\(error.debugDescription))"
		case .setup:
			return ".setup"
		@unknown default:
			return ".unknown (??)"
		}
	}
}

