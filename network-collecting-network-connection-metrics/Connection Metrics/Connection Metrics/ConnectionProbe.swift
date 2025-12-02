/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Establish a probe connection given a host and port.
*/

import Foundation
import Network

// Define a list of supported probe types.
enum ProbeType {
	case tls
	case dtls
	case websocket
}

// Deliver a report back to the caller.
protocol ConnectionProbeDelegate: AnyObject {
	func reportComplete(_ report: Result<NWConnection.EstablishmentReport, NWError>)
}

// Implement a class to configure a probe, run the probe connection,
// and report the results.
class ConnectionProbe {

	// Store the parameters set by the caller.
	private let endpoint: NWEndpoint
	private let probeType: ProbeType
	private weak var delegate: ConnectionProbeDelegate?
	var useLegacyTLSVersion: Bool = false
	var disableOptimisticDNS: Bool = false

	// Store internal state.
	private var connection: NWConnection?
	private var cancelled: Bool = false

	// Configure a new probe.
	init(to endpoint: NWEndpoint, as probeType: ProbeType, delegate: ConnectionProbeDelegate) {
		self.delegate = delegate
		self.endpoint = endpoint
		self.probeType = probeType
	}

	// Implement a helper function to set up a parameters object based
	// on the configuration of the probe.
	private func makeParameters() -> NWParameters {

		// First, create the TLS options.
		let tlsOptions = NWProtocolTLS.Options()

		// Always disable resumption for the probes to measure the
		// full handshake time. You should not disable resumption
		// for general use in your app.
		let securityOptions = tlsOptions.securityProtocolOptions
		sec_protocol_options_set_tls_resumption_enabled(securityOptions, false)

		// Create the parameters based on the probe type.
		let parameters: NWParameters
		switch probeType {
		case .tls:
			if useLegacyTLSVersion {
				// Configure the probes to use a slower version of TLS that incurs more round trips.
				// You will notice the extra round trips more on slow networks.
				sec_protocol_options_set_max_tls_protocol_version(securityOptions, .TLSv12)
			}
			parameters = NWParameters(tls: tlsOptions)
		case .dtls:
			if useLegacyTLSVersion {
				sec_protocol_options_set_max_tls_protocol_version(securityOptions, .DTLSv10)
			}
			parameters = NWParameters(dtls: tlsOptions)
		case .websocket:
			// For WebSocket, start with TLS then add WebSocket on top.
			if useLegacyTLSVersion {
				sec_protocol_options_set_max_tls_protocol_version(securityOptions, .TLSv12)
			}
			parameters = NWParameters(tls: tlsOptions)

			let websocketOptions = NWProtocolWebSocket.Options()
			parameters.defaultProtocolStack.applicationProtocols.insert(websocketOptions, at: 0)
		}

		// Test probes that disable using expired DNS answers.
		// Disabling using expired DNS probes highlights the overhead
		// of waiting for DNS queries on slow networks.
		if disableOptimisticDNS {
			parameters.expiredDNSBehavior = .prohibit
		}

		return parameters
	}

	// Start the probe connection.
	func start() {

		if self.connection != nil || cancelled {
			// If the connection is already started or cancelled, don't start again.
			return
		}

		// Create the connection to the requested endpoint.
		let connection = NWConnection(to: endpoint, using: makeParameters())
		self.connection = connection

		// Handle state updates.
		connection.stateUpdateHandler = { state in
			switch state {
			case .ready:
				// The connection completed, collect the report.
				connection.requestEstablishmentReport(queue: .main) { report in
					if let report = report {
						self.delegate?.reportComplete(.success(report))
					}
					self.cancel()
				}
			case .failed(let error):
				self.delegate?.reportComplete(.failure(error))
			default:
				print("Received state update: \(state)")
			}
		}

		// Start the connection, and request callbacks on the main queue.
		connection.start(queue: .main)
	}

	// Tear down the probe connection.
	func cancel() {
		if cancelled {
			return
		}
		cancelled = true
		connection?.cancel()
		connection = nil
	}
}
