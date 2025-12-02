/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main routing manager.
*/

import Foundation
import AVFoundation
import AVRouting
import os

typealias CustomRowDidTapHandler = (AVCustomRoutingActionItem) -> Void

class RouteManager: NSObject, ObservableObject {
	@Published var hasAuthorizedRoutes = false
	var customRoutingController: AVCustomRoutingController? = nil
	var onSessionUpdateHandler: ((DemoClientSession?, AVCustomDeviceRoute?) -> Void)?
	static let shared = RouteManager()

	private let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "RouteManager")
	private var routeController = RouteController(sessionUpdateHandler: didSessionUpdateShim)
	private var avRouteDetector = AVRouteDetector()
	private(set) var customRowHandler: CustomRowDidTapHandler? =  nil
	private let queue = DispatchQueue(label: "RouteManager")
	private var isActive = false

	override public init() {
		super.init()
		queue.async {
			NotificationCenter.default.addObserver(self,
												   selector: #selector(RouteManager.authorizedRoutesDidChange(notification:)),
												   name: AVCustomRoutingController.authorizedRoutesDidChange,
												   object: nil)
		}
  }

	func activate(customRowHandler handler: @escaping CustomRowDidTapHandler) {
		queue.sync {
			if !isActive {
				isActive = true
				customRowHandler = handler
				customRoutingController = AVCustomRoutingController()
				if customRoutingController != nil {
					customRoutingController!.delegate = routeController
					logger.log("AVCustomRoutingController started")
					updateAuthorizedRoutes()
				}
			}
		}
	}

	func deactivate() {
		queue.sync {
			if isActive {
				isActive = false
				customRoutingController = nil
			}
		}
	}

	func setupRouteDetector() {
		queue.sync {
			if !avRouteDetector.isRouteDetectionEnabled {
				avRouteDetector.isRouteDetectionEnabled = true
			}
		}
	}

	func teardownRouteDetector() {
		queue.sync {
			if avRouteDetector.isRouteDetectionEnabled {
				avRouteDetector.isRouteDetectionEnabled = false
			}
		}
	}

	func anyRouteDetected() -> Bool {
		return avRouteDetector.multipleRoutesDetected
	}

	func removeRoutes() {
		if let customRoutingController = self.customRoutingController {
			let routes = customRoutingController.authorizedRoutes
			if !routes.isEmpty {
				logger.log("Removing \(routes.count) authorized routes")
				routes.forEach { customRoutingController.invalidateAuthorization(for: $0) }
				routeController.stopSessions()
			} else {
				logger.error("Couldn't remove routes as no one is authorized")
			}
		}
	}

	var reconnectionTaskActive = false
	var reconnectionStarted = Date()
	var retryCount = 0

	func serviceReconnection(restart: Bool = false) {
		let reconnectionDelaySecs = 2.0
		logger.log("serviceReconnection posted")
		queue.asyncAfter(deadline: .now() + reconnectionDelaySecs ) { self.serviceReconnectionImpl(restart) }
	}

    // Tries to reconnect if the vendor-specific route controller has an authorized route, if
    // no authorized route is active, or if the route doesn’t reach the reconnection timeout.
    // This function allows authorized routes to settle before activation or deactivatation events.
	private func serviceReconnectionImpl(_ restart: Bool = false) {
		if restart {
			logger.log("Reconnection tasks restarted")
			reconnectionTaskActive = false
		} else {
			logger.log("Reconnection task continues")
		}

		if let customRoutingController = self.customRoutingController {
			let anyActiveRoute = customRoutingController.authorizedRoutes.contains(where: { customRoutingController.isRouteActive($0) })
			let timedOut = reconnectionTaskActive && reconnectionStarted.timeIntervalSinceNow > 60.0 * 8
			let activeSessions = !routeController.activeSessions.isEmpty
			var authorizedRoutes = "YES"
			if self.customRoutingController != nil && self.customRoutingController!.authorizedRoutes.isEmpty {
				authorizedRoutes = "NO"
			}
			logger.log(
                """
                serviceReconnection, Authorized routes: \(authorizedRoutes),
                Active routes: \(anyActiveRoute ? "YES" : "NO"),
                timed out: \(timedOut ? "YES" : "NO"), activeSessions: \(activeSessions ? "YES" : "NO")
                """
            )

			guard !customRoutingController.authorizedRoutes.isEmpty
					&& !anyActiveRoute
					&& !timedOut
					&& !activeSessions else {
				if reconnectionTaskActive {
					reconnectionTaskActive = false
					logger.log("Stopping reconnection task")
				}
				logger.log("serviceReconnection, idle")
				return
			}

			if !reconnectionTaskActive {
				reconnectionTaskActive = true
				reconnectionStarted = Date()
				retryCount = 0
			}
			let routes = customRoutingController.authorizedRoutes
			let nextRouteIndex = retryCount % routes.count
			let nextRoute = routes[nextRouteIndex]
			retryCount += 1
			logger.log("Attempting reconnection to authorized route \(nextRouteIndex)")
			routeController.reconnectRoute(nextRoute, withController: customRoutingController)
		}
	}

	private func didSessionUpdate(_ session: DemoClientSession?, route: AVCustomDeviceRoute?) {
		logger.log("didSessionUpdate")
		if let sessionHandler = onSessionUpdateHandler {
			sessionHandler(session, route)
		}
	}

	private static func didSessionUpdateShim(_ session: DemoClientSession?, route: AVCustomDeviceRoute?) {
		shared.didSessionUpdate(session, route: route)
	}

	@objc
	func authorizedRoutesDidChange(notification: Notification) {
		updateAuthorizedRoutes()
	}

	func updateAuthorizedRoutes() {
		if let customRoutingController = self.customRoutingController {
			let anyAuthRoutes = !customRoutingController.authorizedRoutes.isEmpty
			logger.log("anyAuthRoutes=\(anyAuthRoutes)")
			if anyAuthRoutes != hasAuthorizedRoutes {
				hasAuthorizedRoutes = !customRoutingController.authorizedRoutes.isEmpty
				logger.log("hasAuthorizedRoutes=\(self.hasAuthorizedRoutes)")
				if hasAuthorizedRoutes {
					RouteManager.shared.serviceReconnection(restart: true)
				}
			}
		} else {
			hasAuthorizedRoutes = false
		}
	}
}
