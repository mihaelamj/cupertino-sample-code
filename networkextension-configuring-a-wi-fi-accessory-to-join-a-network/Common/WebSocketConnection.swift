/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The WebSocketConnection is a common WebSocket connection class.
*/

import Foundation
import Network

final class WebSocketConnection {
    
    // MARK: - Private Constants
    
    private let connection: NWConnection
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Public Variables
    
    typealias Delegate = WebSocketConnectionDelegate
    
    weak var delegate: Delegate? = nil
    
    public var connectionStatus: NWConnection.State {
        return connection.state
    }
    
    init(newConnection: NWConnection) {
        connection = newConnection
    }
    
    /// @function startConnection
    /// @discussion Starts the connection and listens for the response to take the next action, that is, set up a receive handler on .ready.
    func startConnection() {
        
        // Receive state updates for the connection and perform actions upon the ready and failed state.
        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Connection established")
                self.delegate?.didEstablishConnection(connection: self, with: nil)
                
            case .preparing:
                print("Connection preparing")
            case .setup:
                print("Connection setup")
            case .waiting(let error):
                // Attempt to account for a disallowed local network privacy prompt.
                if let currentPathDescription = self.connection.currentPath?.debugDescription {
                    print("Check local network privacy permissions: \(currentPathDescription)")
                    self.delegate?.didEstablishConnection(connection: self, with: error)
                } else {
                    print("Connection waiting: \(error.localizedDescription)")
                }
            case .failed(let error):
                print("Connection failed: \(error.localizedDescription)")
                
                // Cancel the connection upon a failure.
                self.connection.cancel()
                
                // Notify your delegate with an error message when the connection fails.
                self.delegate?.didEstablishConnection(connection: self, with: error)
            default:
                break
            }
        }
        
        // Start the connection and send receive responses on the main queue.
        connection.start(queue: .main)
        
        // Set up to receive messages on the connection.
        setupReceiveMessage()
    }
    
    /// @function sendDataOnConnection
    /// @discussion Sends a new WebSocketMessage.
    func sendDataOnConnection(websocketMessage: WebSocketMessage) {
        
        do {
            let data = try encoder.encode(websocketMessage)
            // Create a context to send the WebSocket data with.
            let message = NWProtocolWebSocket.Metadata(opcode: .text)
            let context = NWConnection.ContentContext(identifier: "send",
                                                      metadata: [message])
            
            connection.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed { error in
                if let error = error {
                    print("Error sending data: \(error.localizedDescription)")
                } else {
                    print("\(data.count) bytes sent")
                }
            })
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }
    
    /// @function setupReceiveMessage
    /// @discussion Receives data and parses the data as WebSocketMessage.
    func setupReceiveMessage() {
        
        connection.receiveMessage { (content, context, isComplete, error) in
            var messageLength = 0
            if let messageData = content {
                do {
                    messageLength = messageData.count
                    let receivedMessage = try self.decoder.decode(WebSocketMessage.self, from: messageData)
                    self.delegate?.didReceivedData(connection: self, with: receivedMessage)
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                }
            }
            
            // Check the error about this note.
            if let receivedError = error {
                print("Error on receiveMessage: \(receivedError.localizedDescription)")
                // If there is an error, don't proceed.
                return
            }
            
            // If the process isn’t complete and the connection read data, call setupReceiveMessage() to read data again.
            if !isComplete, messageLength > 0 {
                // The connection calls this to ensure it can read future data.
                self.setupReceiveMessage()
            }
        }
    }
    
    func cancel() {
        connection.cancel()
    }
}

/// The WebSocketConnectionDelegate for notifying the calling class of new data and connection updates.
protocol WebSocketConnectionDelegate: AnyObject {
    func didEstablishConnection(connection: WebSocketConnection, with error: Error?)
    func didReceivedData(connection: WebSocketConnection, with receivedMessage: WebSocketMessage)
}
