/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages the interaction session.
*/

import Foundation
import NearbyInteraction
import MultipeerConnectivity
import UIKit
import ARKit


class NISessionManager: NSObject, NISessionDelegate, ObservableObject, ARSessionDelegate {
    // Immutable properties.
    let findingMode: FindingMode
    let sessionQueue = DispatchQueue(label: "NIJetpack.sessionManager.NISessionQueue", qos: .userInitiated)
    let qualityEstimator: MeasurementQualityEstimator?

    // Mutable properties.
    var session: NISession?
    var peerDiscoveryToken: NIDiscoveryToken?
    var mpc: MPCSession?
    var convergenceContext: NIAlgorithmConvergence?
    var currentNearbyObject: NINearbyObject?
    var connectedPeer: MCPeerID? = nil
    var sharedTokenWithPeer = false
    var arSession: ARSession?

    // Published state properties that the camera assistance view observes.
    @MainActor @Published var connectedPeerName: String = ""
    @MainActor @Published var latestNearbyObject: NINearbyObject?
    @MainActor @Published var isConverged: Bool = false
    @MainActor @Published var showCoachingOverlay: Bool = true
    @MainActor @Published var quality: MeasurementQualityEstimator.MeasurementQuality = .unknown
    @MainActor @Published var currentWorldTransform: simd_float4x4?
    @MainActor @Published var showUpDownText: Bool = false

    init(mode: FindingMode) {
        NSLog("Starting NI session for \(mode).")
        findingMode = mode
        qualityEstimator = findingMode == .visitor ? MeasurementQualityEstimator() : nil
        super.init()
        startup()
    }

    deinit {
        session?.invalidate()
        mpc?.invalidate()
    }
    
    func invalidate() {
        // Pause running `ARsession` explicitly, if any.
        arSession?.pause()
        mpc?.invalidate()
        connectedPeer = nil
        sharedTokenWithPeer = false
        session?.invalidate()
        session = nil
    }

    func startup() {
        // The initial view.
        Task { @MainActor in
            self.updateViewState(with: nil, quality: .unknown, nearbyObject: nil, worldTransform: nil, showUpDownText: false)
        }

        // Create the interaction session.
        session = NISession()
        session?.delegateQueue = sessionQueue
        
        // Set a delegate.
        session?.delegate = self

        // Because this is a new session, reset the token-shared flag.
        sharedTokenWithPeer = false
        connectedPeer = nil

        // Start multipeer connectivity (MPC) to discover peers.
        startupMPC()
    }

    // MARK: - Discovery token sharing and receiving using MPC.

    func startupMPC() {
        if mpc == nil {
            // The app advertises `DiscoveryInfo` within Multipeer Connectivity framework's
            // Bonjour TXT records that identify the device for browsers to see.
            // Here, the app uses `["identity": discoveryInfoIdentity]` to advertise to peers.
            // `LocalID` is the displayName of `MCPeerID` that's sent to peers.

            // Prevent Simulator from finding devices.
            #if targetEnvironment(simulator)
            let serviceIdentity = findingMode == .exhibit ?
            "com.example.apple-samplecode.simulator.wwdctwotwo-nearbyinteraction" :
            "com.apple.apple-samplecode.simulator.nearbyinteraction-edm"
            #else
            let serviceIdentity = "com.example.apple-samplecode.wwdctwotwo-nearbyinteraction"
            #endif
            let localName = UIDevice.current.name
            mpc = MPCSession(localID: localName, service: "nisample", serviceIdentity: serviceIdentity, maxPeers: 1)
            mpc?.peerConnectedHandler = connectedToPeer
            mpc?.peerDataHandler = dataReceivedHandler
            mpc?.peerDisconnectedHandler = disconnectedFromPeer
        }
        mpc?.invalidate()
        mpc?.start()
    }
    
    func tearDownMpc() {
        sharedTokenWithPeer = false
        connectedPeer = nil
        mpc?.invalidate()
        mpc = nil
    }
    
    func setARSession(_ arSession: ARSession) {
        // Set the ARSession to the interaction session before
        // running the interaction session so that the framework doesn't
        // create its own AR session.
        session?.setARSession(arSession)
        self.arSession = arSession
        // Monitor ARKit session events.
        arSession.delegate = self
    }

    @MainActor func updateConnectedPeer(peer: MCPeerID?) {
        connectedPeer = peer
        connectedPeerName = peer?.displayName ?? "iPhone"
    }

    @MainActor func connectedToPeer(peer: MCPeerID) {
        guard let myToken = session?.discoveryToken else {
            fatalError("Unexpectedly failed to initialize nearby interaction session.")
        }

        guard connectedPeer == nil else {
            NSLog("Already connected to a peer.")
            return
        }

        if !sharedTokenWithPeer {
            shareMyDiscoveryToken(token: myToken)
        }

        connectedPeer = peer
        connectedPeerName = peer.displayName.isEmpty ? "iPhone" : peer.displayName
    }

    @MainActor func disconnectedFromPeer(peer: MCPeerID) {
        if connectedPeer == peer {
            connectedPeer = nil
            sharedTokenWithPeer = false
        }
    }

    func dataReceivedHandler(data: Data, peer: MCPeerID) {
        guard let discoveryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
            fatalError("Unexpectedly failed to decode discovery token.")
        }
        Task {
            await self.peerDidShareDiscoveryToken(peer: peer, token: discoveryToken)
        }
    }

    func shareMyDiscoveryToken(token: NIDiscoveryToken) {
        guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            fatalError("Unexpectedly failed to encode discovery token.")
        }
        mpc?.sendDataToAllPeers(data: encodedData)
        sharedTokenWithPeer = true
    }

    @MainActor func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {
        guard connectedPeer == peer else {
            NSLog("Received a token from an unexpected peer.")
            return
        }
        
        // Create a configuration.
        peerDiscoveryToken = token

        let isVisitor = findingMode == .visitor
        sessionQueue.async {
            let config = NINearbyPeerConfiguration(peerToken: token)
            config.isCameraAssistanceEnabled = true
            
            // Use extended distance measurement (EDM) for visitor finding.
            // if either device can't use EDM, don't range them.
            if isVisitor {
                if #available(iOS 17.0, watchOS 10.0, *) {
                    guard NISession.deviceCapabilities.supportsExtendedDistanceMeasurement else {
                        NSLog("This device isn't capable of finding visitors.")
                        return
                    }
                    
                    guard token.deviceCapabilities.supportsExtendedDistanceMeasurement else {
                        NSLog("Peer device \(peer.displayName) isn't capable of finding visitors.")
                        return
                    }
                    
                    config.isExtendedDistanceMeasurementEnabled = true
                    NSLog("The Nearby Interaction session uses extended distance measurement.")
                    
                } else {
                    NSLog("This version of iOS isn't capable of finding visitors.")
                }
            }
            
            NSLog("Start ranging with \(peer.displayName).")
            
            // Run the session.
            self.session?.run(config)
        }
    }
    
    func computeViewState(with context: NIAlgorithmConvergence?, nearbyObject: NINearbyObject?) {
        let esitimateQuality = qualityEstimator?.estimateQuality(update: nearbyObject)
        let quality = esitimateQuality ?? .unknown
        var showUpDownText = false
        var worldTransform: simd_float4x4? = nil
        
        if let object = nearbyObject,
           let distance = object.distance,
           let horizontalAngle = object.horizontalAngle {
            let minimumViewDistance: Float = 10.0
            let minimumViewAngle: Double = Double.pi / (4 + Double(1 - distance / minimumViewDistance))
            let angle = abs(Double(horizontalAngle))
            if (distance <= minimumViewDistance) && (angle <= minimumViewAngle) {
                if (context?.status ?? .unknown) == .converged, let transform = session?.worldTransform(for: object) {
                    worldTransform = transform
                } else {
                    showUpDownText = true
                }
            }
        }
        let showText = showUpDownText
        let transform = worldTransform

        // Update and publish all view-related state to re-render Camera assistance view in `MainActor`.
        Task { @MainActor in
            self.updateViewState(with: context, quality: quality, nearbyObject: nearbyObject,
                                 worldTransform: transform, showUpDownText: showText)
        }
    }

    @MainActor
    func updateViewState(with context: NIAlgorithmConvergence?,
                         quality: MeasurementQualityEstimator.MeasurementQuality,
                         nearbyObject: NINearbyObject?, worldTransform: simd_float4x4?, showUpDownText: Bool) {
        self.convergenceContext = context
        self.quality = quality
        self.latestNearbyObject = nearbyObject
        self.currentWorldTransform = worldTransform
        self.isConverged = context?.status == .converged
        self.showCoachingOverlay = worldTransform == nil
        self.latestNearbyObject = nearbyObject
        self.showUpDownText = showUpDownText
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peerToken = peerDiscoveryToken else {
            fatalError("don't have peer token")
        }

        // Find the right peer.
        let peerObj = nearbyObjects.first { (obj) -> Bool in
            return obj.discoveryToken == peerToken
        }

        guard let nearbyObjectUpdate = peerObj else {
            return
        }
        
        // When the session is ranging with its peer, the data connection might
        // drop; after which which you don't need to keep it.
        // Tear down the MPC session after the app initially started ranging with the peer.
        // After the current ranging session stops and is invalidated, the app
        // restarts a new MPC data connection for a new peer.
        if mpc != nil {
            tearDownMpc()
        }

        // Update and compute with updated `nearbyObject`.
        currentNearbyObject = nearbyObjectUpdate
        computeViewState(with: convergenceContext, nearbyObject: nearbyObjectUpdate)
    }

    func session(_ session: NISession, didUpdateAlgorithmConvergence convergence: NIAlgorithmConvergence, for object: NINearbyObject?) {
        guard let peerToken = peerDiscoveryToken else {
            fatalError("Don't have peer token.")
        }

        guard let nearbyObject = object, nearbyObject.discoveryToken == peerToken else {
            return
        }

        // Update and compute with updated algorithm `convergence` and `nearbyObject`.
        currentNearbyObject = nearbyObject
        convergenceContext = convergence
        computeViewState(with: convergence, nearbyObject: currentNearbyObject)
    }

    func sessionWasSuspended(_ session: NISession) {
    }

    func sessionSuspensionEnded(_ session: NISession) {
        // Session suspension ends. You can run the session again, or restart
        // it if the session was invalid.
        if let config = self.session?.configuration {
            session.run(config)
        } else {
            // Create a valid configuration.
            startup()
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        // Restart discovery to find new peers and create new sessions.
        startup()
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        // If the app doesn't have approval for Nearby Interaction, present
        // an option to open the Settings app where the they can update the access.
        if #available(iOS 17.0, watchOS 10.0, *) {
            switch error {
            case NIError.userDidNotAllow,
                NIError.invalidARConfiguration,
                NIError.incompatiblePeerDevice,
                NIError.activeSessionsLimitExceeded,
                NIError.activeExtendedDistanceSessionsLimitExceeded:
                return
            default:
                break
            }
        } else {
            switch error {
            case NIError.userDidNotAllow,
                NIError.invalidARConfiguration,
                NIError.activeSessionsLimitExceeded:
                return
            default:
                break
            }
        }
        
        // Recreate a valid session in other failure cases.
        startup()
    }

    // Returns `false` as required by the `NISession.setARSession(_:)` documentation.
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return false
    }
}

// A helper class for "visitor finding mode" where someone might need to find a
// moving peer device that is far away.
class MeasurementQualityEstimator {

    // Define the criteria that qualify a peer with "good" characteristics:
    // these include:

    // A time window, in seconds.
    let freshnessWindow = TimeInterval(floatLiteral: 2.0)
    // A minimum number of samples in that time window.
    let minSamples: Int = 8
    // A maximim distance, in meters.
    let maxDistance: Float = 50
    // A minimum distance, in meters.
    let closeDistance: Float = 10
    
    // A buffer to hold the individual quality measurements.
    private var measurements: [TimedNIObject] = []
    
    // An enumeration that defines levels of peer quality.
    enum MeasurementQuality {
        // The peer fails to meet any of the measurement quality criteria.
        case unknown

        // The extended distance measurements indicate the peer iPhone or device
        // satisfies the criteria for "good" quality and falls inside the
        // minimum and maximum acceptable distance.
        case good

        // The extended distance measurements indicate the current device
        // satisfies the criteria for being "close" to the peer iPhone or device.
        case close
    }

    // A structure that captures the range of a peer at a specific time.
    struct TimedNIObject {
        let time: TimeInterval
        let distance: Float
    }

    func estimateQuality(update: NINearbyObject?) -> MeasurementQuality {
        let timeNow = NSDate().timeIntervalSinceReferenceDate
        if let distance = update?.distance {
            if let lastMeasureMent = measurements.last {
                if lastMeasureMent.distance != distance {
                    // Before adding a new measurement to buffers, check
                    // if the reported distance is unique.
                    measurements.append(TimedNIObject(time: timeNow, distance: distance))
                }
            } else {
                // If the buffer is empty, unconditionally add the new measurement.
                measurements.append(TimedNIObject(time: timeNow, distance: distance))
            }
        }
        let validTimestamp = timeNow - freshnessWindow
        measurements.removeAll { $0.time < validTimestamp }
        if measurements.count > minSamples, let lastDistance = measurements.last?.distance {
            if lastDistance <= closeDistance { return .close }
            return lastDistance < maxDistance ? .good : .unknown
        }
        return .unknown
    }
}
