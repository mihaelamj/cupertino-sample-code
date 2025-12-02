/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A delegate for media route controlling.
*/

import AVRouting
import CoreBluetooth
import Network
import os

class RouteController: NSObject, AVCustomRoutingControllerDelegate {

	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "RouteController")
	let onSessionUpdated: (DemoClientSession?, AVCustomDeviceRoute?) -> Void

	var activeSessions: [AVCustomDeviceRoute: (connection: DemoUdpConnection, session: DemoClientSession)] = [:]
	var currentRoute: AVCustomDeviceRoute?

	init(sessionUpdateHandler: @escaping (DemoClientSession?, AVCustomDeviceRoute?) -> Void) {
		logger.log("Init RouteController")

		onSessionUpdated = sessionUpdateHandler
	}

	func handleRouteEvent(_ controller: AVCustomRoutingController,
	                      handle event: AVCustomRoutingEvent,
	                      completionHandler: @escaping (Bool) -> Void) {
		logger.log("EVENT: \(event.reason.rawValue), total \(controller.authorizedRoutes.count) routes active")

		switch event.reason {
		case .activate, .reactivate:
			// Prioritize the network endpoint.
			if let endpoint = event.route.networkEndpoint {
				if let connectedRoute = currentRoute {
					if routesHaveSameNetworkEndpoint(event.route, connectedRoute) {
						logger.log("The current route network endpoint was re-activated")
						currentRoute = connectedRoute
						completionHandler(true)
						return
					} else {
						logger.log("The current route was overridden by a new activation ")
						cleanupRoute(connectedRoute)
					}
				}
				let nwEndpoint: NWEndpoint = .opaque(endpoint)
				logger.log("APP TXT RECORD: \(nwEndpoint.txtRecord?.dictionary.description ?? "EMPTY TXT")")
				processNWEndpoint(nwEndpoint, route: event.route, completion: { [self] (result: Bool) in

					completionHandler(result)
					if !result {
						self.cleanupRoute(event.route)
					}

				})
			} else if let bluetoothIdentifier = event.route.bluetoothIdentifier {
				logger.log("Process Bluetooth Identifier: \(bluetoothIdentifier)")
				processBluetoothIdentifier(bluetoothIdentifier)
			} else {
				logger.error("Failed to get network or bluetooth endpoint ")
				completionHandler(false)
			}

		case .deactivate:

			completionHandler(true)
			logger.log("EVENT .deactivate")
			if event.route.networkEndpoint != nil {
				if let session = getSession(for: event.route) {
					logger.log("Disconnecting Network Endpoint")
					session.stop() // The expected cleanup on disconnection.
				} else {
					logger.log("Removing Network Endpoint")
					cleanupRoute(event.route)
				}
			}
		default:
			logger.error("Unknown AVCustomRoutingEvent event type")
		}
	}

	func reconnectRoute(_ route: AVCustomDeviceRoute, withController controller: AVCustomRoutingController) {
		if let endpoint = route.networkEndpoint {
			logger.log("Recovering activeRoute connection")
			let nwEndpoint: NWEndpoint = .opaque(endpoint)
			processNWEndpoint(nwEndpoint, route: route, completion: { (result: Bool) in
				if !result {
					self.logger.log("Route reconnection failed.")
					self.cleanupRoute(route)
				}
			})
		}
	}

	// MARK: AVCustomRoutingControllerDelegate delegate
	func customRoutingController(_ controller: AVCustomRoutingController,
                                 didTimeOutVendorSpecificRouteEvent event: AVCustomRoutingEvent) {
		logger.log("EVENT TIMED OUT: \(event.reason.rawValue)")
	}

	func customRoutingController(_ controller: AVCustomRoutingController,
	                             handle event: AVCustomRoutingEvent,
	                             completionHandler: @escaping (Bool) -> Void) {
		handleRouteEvent(controller, handle: event, completionHandler: completionHandler)
	}

	func customRoutingController(_ controller: AVCustomRoutingController, didSelect customActionItem: AVCustomRoutingActionItem) {
		if let handler = RouteManager.shared.customRowHandler {
			handler(customActionItem)
		}
	}

	// MARK: helpers
	
    // Indicates whether the endpoint is connected.
	func processNWEndpoint(_ nwEndpoint: NWEndpoint, route: AVCustomDeviceRoute, completion:@escaping ((Bool) -> Void)) {
		switch nwEndpoint {
		case .hostPort(let host, let port):
			logger.log("Got hostPort host, \(host.debugDescription), port, \(port.debugDescription)")
		case .service(let name, let type, let domain, let interface):
			logger.log("Got service name, \(name), type, \(type), domain, \(domain), interface, \(String(describing: interface))")
		case .url(let location):
			logger.log("Got url location, \(location)")
		case .unix(let path):
			logger.log("Got unix path, \(path)")
		case .opaque:
			logger.log("Got opaque endpoint")
			
            // Expect only one remote network connection at a time.
			let newConnection = DemoUdpConnection(nwConnection: NWConnection(to: nwEndpoint, using: .udp))
			let newSession = DemoClientSession()
			newConnection.delegate = newSession
			activeSessions[route] = (connection: newConnection, session: newSession)
			newSession.stateUpdatedHandler = { [self, completion] (state: DemoSessionState) in
				let prevSession = getCurrentSession()
				let prevRoute = currentRoute
				switch state {
				case .connected:
					logger.log("Route connection completed")
					currentRoute = route
					if let controller = getController() {
						// Ensure reconnections are active.
						controller.setActive(true, for: route)
					}
					completion(true)
				case .disconnected:
					if let controller = getController() {
						controller.setActive(false, for: route)
						if let controllerRoutes = findControllerRoutes(controller, for: route) {
							// The session disconnects a route.
							logger.log("Session disconnected. Route session completed, removing.")
							for route in controllerRoutes {
								cleanupRoute(route)
							}
						} else {
							logger.error("Session disconnected. No active route disconnected.")
						}
					} else {
						logger.log("Ignoring disconnected unknown disposed route session.")
					}
					if let route = currentRoute, let session = getSession(for: route) {
						if session === newSession {
							// This session is still active in the UI.
							cleanupRoute(route)
						}
					}
				default:
					break
				}
				if getCurrentSession() !== prevSession {
					onSessionUpdated(getCurrentSession(), route)
				}
				let reconnectionNeedsRestart = currentRoute == nil && prevRoute != nil
                // Stop if the route is active. Restart or continue if it isn’t.
				RouteManager.shared.serviceReconnection(restart: reconnectionNeedsRestart)
			}
			newConnection.start()
			return
		default:
			logger.log("Got unexpected network endpoint '\(String(describing: nwEndpoint))")
		}
		completion(false)
	}

	private func routesHaveSameNetworkEndpoint(_ route1: AVCustomDeviceRoute, _ route2: AVCustomDeviceRoute) -> Bool {
		if let ep1 = route1.networkEndpoint, let ep2 = route2.networkEndpoint {
			return ep1.isEqual(ep2)
		}
		return false
	}

	private func findControllerRoutes(_ controller: AVCustomRoutingController, for route: AVCustomDeviceRoute) -> [AVCustomDeviceRoute]? {
		let foundRoutes = controller.authorizedRoutes.filter { routesHaveSameNetworkEndpoint($0, route) }
		if foundRoutes.count > 1 {
			logger.log("Multiple routes were found for target route endpoint: \(foundRoutes)")
		}
		return foundRoutes
	}

	private func processBluetoothIdentifier(_ bluetoothDevice: UUID) {
		// The sample app intentionally leaves this implementation blank.
	}

    // Cleans up after a disconnected session.
	func stopSessions() {
		for (_, session) in activeSessions.values {
			session.stop()
		}
	}

	private func getCurrentSession() -> DemoClientSession? {
		if let route = currentRoute {
			return getSession(for: route)
		}
		return nil
	}

	private func findRouteByNetworkEndpoint(for route: AVCustomDeviceRoute) -> AVCustomDeviceRoute? {
		if activeSessions[route] != nil {
			return route
		}
		// The route event instances have different map hashes. Match the route for consistency.
		if let matchedRoute = activeSessions.keys.first(where: { routesHaveSameNetworkEndpoint($0, route) }) {
			logger.log("Route sessions recoverable by network endpoint.")
			return matchedRoute
		}
		return nil
	}

	private func getSession(for someRoute: AVCustomDeviceRoute) -> DemoClientSession? {
		if let route = findRouteByNetworkEndpoint(for: someRoute) {
			if let endpoint = activeSessions[route] {
				return endpoint.session
			}
		}
		return nil
	}

	private func getController() -> AVCustomRoutingController? {
		return RouteManager.shared.customRoutingController
	}

	private func cleanupRoute(_ someRoute: AVCustomDeviceRoute) {
		if let controller = getController() {
			controller.setActive(false, for: someRoute)
		}

		if let route = findRouteByNetworkEndpoint(for: someRoute) {
			// The network endpoint is no longer active.
			let oldSession = getCurrentSession()
			if currentRoute == route {
				currentRoute = nil
			}
			if let (_, session) = activeSessions.removeValue(forKey: route) {
				session.stop()
			}
			if oldSession !== getCurrentSession() {
				onSessionUpdated(getCurrentSession(), currentRoute)
			}
		}
	}
}
