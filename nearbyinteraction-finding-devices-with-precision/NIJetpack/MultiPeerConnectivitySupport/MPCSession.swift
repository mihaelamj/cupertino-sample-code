/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that manages peer discovery token exchange over the local network.
*/

import Foundation
import MultipeerConnectivity

struct MPCSessionConstants {
    static let kKeyIdentity: String = "identity"
}

class MPCSession: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    var peerDataHandler: ((Data, MCPeerID) -> Void)?
    var peerConnectedHandler: ((MCPeerID) -> Void)?
    var peerDisconnectedHandler: ((MCPeerID) -> Void)?

    private let serviceString: String
    private let mcSession: MCSession
    private let localPeerID: MCPeerID
    private let mcAdvertiser: MCNearbyServiceAdvertiser
    private let discoveryInfoIdentity: String
    private let maxNumPeers: Int
    
    private var mcBrowser: MCNearbyServiceBrowser?

    private var currentConnectedPeers: [MCPeerID]
    // The `SerialQueue` the app uses to synchronize connections, disconnections, and send and accept invitations.
    private var mpcSessionSerialQueue: DispatchQueue

    init(localID: String, service: String, serviceIdentity: String, maxPeers: Int) {
        localPeerID = MCPeerID(displayName: localID)
        serviceString = service
        discoveryInfoIdentity = serviceIdentity
        mcSession = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        // Advertise `DiscoveryInfo` with Bonjour TXT records that identify the device for browsers to see.
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: localPeerID,
                                                 discoveryInfo: [MPCSessionConstants.kKeyIdentity: discoveryInfoIdentity],
                                                 serviceType: serviceString)
        mcBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceString)
        maxNumPeers = maxPeers
        currentConnectedPeers = [MCPeerID]()
        mpcSessionSerialQueue = DispatchQueue(label: "NIJetpack.mpcQueue", qos: .default)
        super.init()
        mcSession.delegate = self
        mcAdvertiser.delegate = self
        mcBrowser?.delegate = self
    }

    // MARK: - `MPCSession` public methods.
    func start() {
        NSLog("Start advertising.")
        mcAdvertiser.startAdvertisingPeer()
        if mcBrowser == nil {
            mcBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceString)
            mcBrowser?.delegate = self
        }
        mcBrowser?.startBrowsingForPeers()
    }

    func suspend() {
        NSLog("Suspend advertising.")
        mcAdvertiser.stopAdvertisingPeer()
        mcBrowser = nil
    }

    func invalidate() {
        NSLog("Invalidating the session and disconnecting peers.")
        suspend()
        mcSession.disconnect()
        currentConnectedPeers.removeAll()
    }

    func sendDataToAllPeers(data: Data) {
        sendData(data: data, peers: mcSession.connectedPeers, mode: .reliable)
    }

    func sendData(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode) {
        do {
            try mcSession.send(data, toPeers: peers, with: mode)
        } catch let error {
            NSLog("Error sending data: \(error).")
        }
    }

    // MARK: - `MPCSession` private methods.
    private func peerConnected(peerID: MCPeerID) {
        NSLog("Connected peer: \(peerID).")
        // Suspend advertising and browsing peers if `currentConnectedPeers`
        // exceed `maxNumPeers`.
        guard currentConnectedPeers.count < maxNumPeers else {
            self.suspend()
            return
        }
      
        guard !currentConnectedPeers.contains(peerID) else {
            return
        }
    
        currentConnectedPeers.append(peerID)
        if let handler = peerConnectedHandler {
            DispatchQueue.main.async {
                handler(peerID)
            }
        }
    }

    private func peerDisconnected(peerID: MCPeerID) {
        NSLog("Disconnected peer: \(peerID).")
        // Restart advertising and browsing peers if `connectedPeers` is less
        // than `maxNumPeers`.
        guard currentConnectedPeers.contains(peerID) else {
            return
        }
        currentConnectedPeers.removeAll { $0 == peerID }

        if let handler = peerDisconnectedHandler {
            DispatchQueue.main.async {
                handler(peerID)
            }
        }
    }

    // MARK: - `MCSessionDelegate` methods.
    internal func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        mpcSessionSerialQueue.sync { [weak self] in
            switch state {
            case .connected:
                self?.peerConnected(peerID: peerID)
            case .notConnected:
                self?.peerDisconnected(peerID: peerID)
            case .connecting:
                break
            @unknown default:
                fatalError("Unhandled MCSessionState.")
            }
        }
    }

    internal func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let handler = peerDataHandler {
            DispatchQueue.main.async {
                handler(data, peerID)
            }
        }
    }

    internal func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // The sample app intentionally omits this implementation.
    }

    internal func session(_ session: MCSession,
                          didStartReceivingResourceWithName resourceName: String,
                          fromPeer peerID: MCPeerID,
                          with progress: Progress) {
        // The sample app intentionally omits this implementation.
    }

    internal func session(_ session: MCSession,
                          didFinishReceivingResourceWithName resourceName: String,
                          fromPeer peerID: MCPeerID,
                          at localURL: URL?,
                          withError error: Error?) {
        // The sample app intentionally omits this implementation.
    }

    // MARK: - `MCNearbyServiceBrowserDelegate` methods.
    
    internal func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Only connect with peers matched with the same `identityInfo` (both key and value).
        guard let identityValue = info?[MPCSessionConstants.kKeyIdentity], identityValue == discoveryInfoIdentity else {
            return
        }
        mpcSessionSerialQueue.sync { [weak self] in
            guard let self else { return }
            // Invite a new peer if the current number of peers is less than
            // the maximum.
            if self.mcSession.connectedPeers.count < self.maxNumPeers {
                browser.invitePeer(peerID, to: self.mcSession, withContext: nil, timeout: 10)
            }
        }
    }

    internal func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // The sample app intentionally omits this implementation.
    }

    // MARK: - `MCNearbyServiceAdvertiserDelegate`.
    internal func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                             didReceiveInvitationFromPeer peerID: MCPeerID,
                             withContext context: Data?,
                             invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        mpcSessionSerialQueue.sync { [weak self] in
            guard let self else { return }
            // Accept the invitation only if the current number of peers is
            // less than the maximum.
            if self.mcSession.connectedPeers.count < self.maxNumPeers {
                invitationHandler(true, self.mcSession)
            }
        }
    }
}
