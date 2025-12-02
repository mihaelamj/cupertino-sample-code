/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages the simulation state.
*/

import Foundation
import Observation
import SpriteKit
import WiFiAware
import Network
import SwiftUI
import OSLog

@MainActor @Observable class SimulationEngine {
    private let mode: Mode
    private var scene: SimulationScene?

    var networkState: NetworkState
    var deviceConnections: [WAPairedDevice: ConnectionDetail] = [:]
    var wifiAwareError: WiFiAwareError?
    var showError = false

    private let connectionManager: ConnectionManager
    private let networkManager: NetworkManager

    @ObservationIgnored private var eventHandlerTasks: [Task<Void, Error>] = []
    @ObservationIgnored private var networkTask: Task<Void, Error>?
    @ObservationIgnored private var simulationEventsTask: Task<Void, Error>?
    @ObservationIgnored private var monitorTimer: Timer?

    init(_ mode: Mode) {
        self.mode = mode
        self.networkState = mode == .host ? .host(.stopped) : .viewer(.stopped)

        connectionManager = ConnectionManager()
        networkManager = NetworkManager(connectionManager: connectionManager)

        eventHandlerTasks.append(setupEventHandler(for: networkManager.localEvents))
        eventHandlerTasks.append(setupEventHandler(for: networkManager.networkEvents))
        eventHandlerTasks.append(setupEventHandler(for: connectionManager.localEvents))
        eventHandlerTasks.append(setupEventHandler(for: connectionManager.networkEvents))

        startConnectionMonitor(interval: 3.0)
    }

    func setupEventHandler<T>(for stream: AsyncStream<T>) -> Task<Void, Error> {
        return Task {
            for await event in stream {
                if T.self == LocalEvent.self {
                    await handleLocalEvent(event as? LocalEvent)
                } else if T.self == NetworkEvent.self {
                    await handleNetworkEvent(event as? NetworkEvent)
                }
            }
        }
    }

    func startConnectionMonitor(interval: TimeInterval) {
        monitorTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            Task { [weak self] in
                try await self?.connectionManager.monitor()
            }
        }
    }

    func setup(with scene: SimulationScene) {
        self.scene = scene
        scene.setup(as: mode)

        guard let simulationEvents = scene.localEvents else { return }
        simulationEventsTask = Task {
            for await event in simulationEvents {
                await handleLocalEvent(event)
            }
        }
    }

    func handleLocalEvent(_ event: LocalEvent?) async {
        guard let event else { return }

        switch event {
        case .listenerRunning, .browserRunning:
            networkState = mode == .host ? .host(.publishing) : .viewer(.browsing)

        case .connecting:
            networkState = .viewer(.connecting)

        case .browserStopped(let error), .listenerStopped(let error):
            networkState = mode == .host ? .host(.stopped) : .viewer(.stopped)

            if let waError = error {
                wifiAwareError = WiFiAwareError(waError, category: mode == .host ? .listener : .browser)
                showError = true
            }

        case .connection(let conectionEvent):
            await handleConnectionEvent(conectionEvent)

        case .satelliteMovedTo(let position):
            if mode == .host, let scene {
                await networkManager.sendToAll(.satelliteMovedTo(position: position, dimensions: scene.frame.size))
            }
        }
    }

    func handleConnectionEvent(_ event: LocalEvent.ConnectionEvent) async {
        switch event {
        case .ready(let device, let connectionDetail):
            deviceConnections[device] = connectionDetail
            if mode == .viewer {
                networkTask?.cancel()
                networkTask = nil
                scene?.enableSatellite()

                await networkManager.send(.startStreaming, to: connectionDetail.connection)
                networkState = .viewer(.connected)
            }

        case .performance(let device, let connectionDetail):
            deviceConnections[device] = connectionDetail

        case .stopped(let device, let connectionID, let error):
            deviceConnections.removeValue(forKey: device)
            await connectionManager.invalidate(connectionID)
            if mode == .viewer {
                networkState = .viewer(.stopped)
                scene?.disableSatellite()
            }

            if let waError = error {
                wifiAwareError = WiFiAwareError(waError, category: .connection)
                showError = true
            }
        }
    }

    func handleNetworkEvent(_ event: NetworkEvent?) async {
        guard let event else { return }

        switch event {
        case .startStreaming: logger.info("Received Start streaming")
        case .satelliteMovedTo(position: let position, dimensions: let dimensions):
            if mode == .viewer {
                scene?.moveSatellite(to: position, using: dimensions)
            }
        }
    }

    func run() -> Task<Void, Error>? {
        networkTask = Task {
            _ = try await withTaskCancellationHandler {
                try await mode == .host ? networkManager.listen() : networkManager.browse()
            } onCancel: {
                Task { @MainActor in
                    networkState = mode == .host ? .host(.stopped) : .viewer(.stopped)
                }
            }
        }

        return networkTask
    }

    func stopConnection(to device: WAPairedDevice) async {
        if let connection = deviceConnections[device]?.connection {
            await connectionManager.stop(connection)
        } else {
            logger.error("Unable to find the connection for \(device)")
        }
    }

    nonisolated func stopConnectionMonitor() {
        Task { @MainActor in
            monitorTimer?.invalidate()
            monitorTimer = nil
        }
    }

    deinit {
        simulationEventsTask?.cancel()
        simulationEventsTask = nil

        for task in eventHandlerTasks {
            task.cancel()
        }
        eventHandlerTasks.removeAll()

        networkTask?.cancel()
        networkTask = nil

        stopConnectionMonitor()
    }
}

struct ConnectionDetail: Sendable, Equatable {
    let connection: WiFiAwareConnection
    let performanceReport: WAPerformanceReport

    public static func == (lhs: ConnectionDetail, rhs: ConnectionDetail) -> Bool {
        return lhs.performanceReport.localTimestamp == rhs.performanceReport.localTimestamp
    }
}

enum LocalEvent: Sendable {
    case browserRunning
    case connecting
    case browserStopped(WAError?)

    case listenerRunning
    case listenerStopped(WAError?)

    enum ConnectionEvent {
        case ready(WAPairedDevice, ConnectionDetail)
        case performance(WAPairedDevice, ConnectionDetail)
        case stopped(WAPairedDevice, WiFiAwareConnectionID, WAError?)
    }
    case connection(ConnectionEvent)

    case satelliteMovedTo(CGPoint)
}
