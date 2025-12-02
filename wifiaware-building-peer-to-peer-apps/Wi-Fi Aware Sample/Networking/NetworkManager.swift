/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages Wi-Fi Aware networking.
*/

import WiFiAware
import Network
import OSLog

actor NetworkManager {
    public let localEvents: AsyncStream<LocalEvent>
    private let localEventsContinuation: AsyncStream<LocalEvent>.Continuation

    public let networkEvents: AsyncStream<NetworkEvent>
    private let networkEventsContinuation: AsyncStream<NetworkEvent>.Continuation

    private let connectionManager: ConnectionManager

    init(connectionManager: ConnectionManager) {
        (self.localEvents, self.localEventsContinuation) = AsyncStream.makeStream(of: LocalEvent.self)
        (self.networkEvents, self.networkEventsContinuation) = AsyncStream.makeStream(of: NetworkEvent.self)

        self.connectionManager = connectionManager
    }

    // MARK: - NetworkListener (Publisher)

    func listen() async throws {
        logger.info("Start NetworkListener")

        try await NetworkListener(for:
            .wifiAware(.connecting(to: .simulationService, from: .allPairedDevices)),
        using: .parameters {
            Coder(receiving: NetworkEvent.self, sending: NetworkEvent.self, using: NetworkJSONCoder()) {
                UDP()
            }
        }
        .wifiAware { $0.performanceMode = appPerformanceMode }
        .serviceClass(appServiceClass))
        .onStateUpdate { listener, state in
            logger.info("\(String(describing: listener)): \(String(describing: state))")

            switch state {
            case .setup, .waiting: break
            case .ready: self.localEventsContinuation.yield(.listenerRunning)
            case .failed(let error): self.localEventsContinuation.yield(.listenerStopped(error.wifiAware))
            case .cancelled: self.localEventsContinuation.yield(.listenerStopped(nil))
            default: break
            }
        }
        .run { connection in
            logger.info("Received connection: \(String(describing: connection))")
            await self.connectionManager.add(connection)
        }
    }

    // MARK: - NetworkBrowser (Subscriber)

    func browse() async throws {
        logger.info("Start NetworkBrowser")

        let browser = NetworkBrowser(for:
            .wifiAware(.connecting(to: .allPairedDevices, from: .simulationService))
        )
        .onStateUpdate { browser, state in
            logger.info("\(String(describing: browser)): \(String(describing: state))")

            switch state {
            case .setup, .waiting: break
            case .ready: self.localEventsContinuation.yield(.browserRunning)
            case .failed(let error): self.localEventsContinuation.yield(.browserStopped(error.wifiAware))
            case .cancelled: self.localEventsContinuation.yield(.browserStopped(nil))
            default: break
            }
        }

        // Connect to the first discovered endpoint.
        let endpoint = try await browser.run { waEndpoints in
            logger.info("Discovered: \(waEndpoints)")
            if let firstEndpoint = waEndpoints.first {
                return .finish(firstEndpoint)
            } else {
                return .continue
            }
        }

        logger.info("Attempting connection to: \(endpoint)")
        localEventsContinuation.yield(.connecting)
        await connectionManager.setupConnection(to: endpoint)
    }

    // MARK: - Send

    func send(_ event: NetworkEvent, to connection: WiFiAwareConnection) async {
        await connectionManager.send(event, to: connection)
    }

    func sendToAll(_ event: NetworkEvent) async {
        await connectionManager.sendToAll(event)
    }

    // MARK: - Deinit

    deinit {
        localEventsContinuation.finish()
        networkEventsContinuation.finish()
    }
}

public enum NetworkEvent: Codable, Sendable {
    case startStreaming
    case satelliteMovedTo(position: CGPoint, dimensions: CGSize)
}
