/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The WebSocketListener to listen for incoming connections.
*/

import Foundation
import Network

class WebSocketListener {
    
    // MARK: - Private Variables
    
    private var websocketListener: NWListener?
    private var didListenerFail: Bool = false
    private var didConnectionSetup: Bool = false
    
    // MARK: - Public constants
    
    public static let shared = WebSocketListener()
    
    // MARK: - Public Variables
    
    typealias Delegate = WebSocketListenerDelegate
    
    public weak var delegate: Delegate?
    public var listenerDidStart = false
    public var listenerPort = ""
    
    /// @function startListener
    /// @discussion Starts the listener for incoming connections.  Notifies the delegate on failure or ready state.
    func startListener(psk: String, pskIdentity: String) {
        do {
            let port = NWEndpoint.Port(Constants.port)!
            let tlsParams = NWParameters(psk: psk, pskIdentity: pskIdentity)
            let listener = try NWListener(using: tlsParams, on: port)
            websocketListener = listener
            
            // Handles state updates for the readiness of the listener.
            listener.stateUpdateHandler = { newState in
                
                switch newState {
                case .ready:
                    if let port = listener.port {
                        let listenerMessage = "Listener - ready on port \(port)"
                        self.listenerDidStart = true
                        self.listenerPort = "\(port)"
                        self.delegate?.didReceiveListenerUpdate(listener: self, didUpdateMessage: listenerMessage)
                    }
                case .failed(let error):
                    
                    listener.cancel()
                    if self.didListenerFail {
                        self.didListenerFail = true // Retry once and then give up.
                        self.startListener(psk: psk, pskIdentity: pskIdentity)
                    } else {
                        // If the listener goes into the failed state, cancel and restart.
                        let errorMessage = "Listener - failed with \(error.localizedDescription), restarting"
                        self.delegate?.didReceiveListenerUpdate(listener: self, didUpdateMessage: errorMessage)
                    }
                default:
                    break
                }
            }
            
            // Receive the new incoming connection.
            listener.newConnectionHandler = { newConnection in
                
                if self.didConnectionSetup {
                    return
                }
                self.didConnectionSetup = true
                let listenerMessage = "Listener - received a new connection"
                self.delegate?.didReceiveListenerUpdate(listener: self, didUpdateMessage: listenerMessage)
                self.delegate?.didReceiveNewConnection(listener: self, newConnection: newConnection)
            }
            
            // Start listening, and request updates on the main queue.
            listener.start(queue: .main)
        } catch {
            let errorMessage = "WebSocket Listener failed to start: \(error.localizedDescription)"
            self.delegate?.didReceiveListenerUpdate(listener: self, didUpdateMessage: errorMessage)
        }
    }
    
    func cancelListener() {
        self.listenerDidStart = false
        websocketListener?.cancel()
    }
    
    private init() {
        // The empty initializer to force the shared instance.
    }
}

/// The WebSocketListenerDelegate for notifying the calling class on a new connection or a listener update.
protocol WebSocketListenerDelegate: AnyObject {
    func didReceiveListenerUpdate(listener: WebSocketListener, didUpdateMessage: String)
    func didReceiveNewConnection(listener: WebSocketListener, newConnection: NWConnection)
}

