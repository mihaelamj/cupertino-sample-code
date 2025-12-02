/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller to enter a network passphrase and send the SSID and passphrase to BrandXAccessory.
*/
import UIKit
import Network

final class SetupSendDataViewController: SetupBaseViewController {
    
    // MARK: - @IBOutlet variables
    
    @IBOutlet private weak var sendNetworkDataButton: UIButton!
    @IBOutlet private weak var enterNetworkPassphraseButton: UIButton!
    @IBOutlet private weak var instructionLabel: UILabel!
    
    // MARK: - Public Variables
    
    public var didPassNetworkDataSuccessfully = false
    public var wifiPassphrase: String = ""
    
    // MARK: - Private Variables
    
    private var websocketConnection: WebSocketConnection?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sendNetworkDataButton.isEnabled = false
        self.title = "Send Network Data to BrandXAccessory"
    }
    
    // MARK: - IBActions
    
    @IBAction func sendNetworkDataAction() {
        
        if didPassNetworkDataSuccessfully {
            if let removeHotspotVC = storyBoard.instantiateViewController(identifier: removeHotspotVCStoryBoardIdentifier)
                as? SetupRemoveHotspotViewController {
                self.navigationController?.pushViewController(removeHotspotVC, animated: true)
                return
            }
        } else if websocketConnection == nil,
                  // Connect to the accessory with the supplied information from the QR code.
                  let connectionTuple = DeviceNetworkManager.shared.accessoryNetwork?.accessoryConnectionInfo {
            
            // (scheme: String, host: String, port: String, psk: String, pskIdentity: String)
            var urlComponents = URLComponents()
            urlComponents.scheme = connectionTuple.scheme
            urlComponents.host = connectionTuple.host
            urlComponents.port = Int(connectionTuple.port)
            
            guard let wsURL = urlComponents.url else {
                print("Failed to build a proper URL out of URLComponents")
                return
            }
            
            // Create the new NWConnection object.
            let tlsParams = NWParameters(psk: connectionTuple.psk, pskIdentity: connectionTuple.pskIdentity)
            
            let urlConnectionEndpoint = NWEndpoint.url(wsURL)
            let connection = NWConnection(to: urlConnectionEndpoint, using: tlsParams)
            
            let websocket = WebSocketConnection(newConnection: connection)
            websocketConnection = websocket
            websocket.delegate = self
            websocket.startConnection()
        }
    }
    
    @IBAction func enterNetworkPassphraseAction() {
        let message = "Please set your network passphrase to send to BrandXAccesory"
        let networkAlert = UIAlertController(title: NSLocalizedString("Network Passphrase", comment: "Network Passphrase"),
                                             message: NSLocalizedString(message, comment: "Set Passphrase"),
                                             preferredStyle: .alert)
        // Add the Save button to extract the passphrase.
        let setPassPhraseAction = UIAlertAction(title: NSLocalizedString("Set Passphrase", comment: "Set Passphrase"),
                                                style: .default, handler: { [weak self] (alertAction) in
                                                    guard let strongSelf = self else { return }
                                                    
                                                    guard let textfields = networkAlert.textFields,
                                                          !textfields.isEmpty else {
                                                        print("Error capturing textfield")
                                                        return
                                                    }
                                                    let textfield = textfields[0] as UITextField
                                                    // Only validate that text is present.
                                                    if let passphrase = textfield.text,
                                                       !passphrase.isEmpty {
                                                        strongSelf.wifiPassphrase = passphrase
                                                        strongSelf.sendNetworkDataButton.isEnabled = true
                                                        strongSelf.enterNetworkPassphraseButton.isEnabled = false
                                                    } else {
                                                        print("No Passphrase entered")
                                                    }
                                                })
        networkAlert.addAction(setPassPhraseAction)
        
        // Add the Cancel button.
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .default, handler: nil)
        networkAlert.addAction(cancelAction)
        
        networkAlert.addTextField(configurationHandler: { (uiTextField) in
            uiTextField.placeholder = "Passphrase"
        })
        // Present the alert.
        self.present(networkAlert, animated: true, completion: nil)
    }
}

// MARK: - WebSocketConnectionDelegate Methods

/// The Extension for receiving WebSocket connection updates.
extension SetupSendDataViewController: WebSocketConnectionDelegate {
    
    /// @function didEstablishConnection
    /// @discussion Automatically sends the network information when the app establishes a valid WebSocket connection.
    func didEstablishConnection(connection: WebSocketConnection, with error: Error?) {
        if error == nil {
            let message = WebSocketMessage(ssid: DeviceNetworkManager.shared.getOriginalAssociatedSSID(),
                                           passphrase: wifiPassphrase, status: "")
            connection.sendDataOnConnection(websocketMessage: message)
        } else {
            instructionLabel.text = error?.localizedDescription
            websocketConnection = nil
        }
    }
    
    /// @function didReceivedData
    /// @discussion Validates the response and instructs the user to remove the configuration (if it's still present from joinOnce).
    func didReceivedData(connection: WebSocketConnection, with messageResponse: WebSocketMessage) {
        
        var instructionMessage = "\(messageResponse.ssid):\(messageResponse.passphrase)"
        if messageResponse.status == "ACK" {
            // Make sure to instruct the user to go back to the previously connected network.
            instructionMessage = "Network info acknowledged, disconnect and go back to \(DeviceNetworkManager.shared.getOriginalAssociatedSSID())"
            sendNetworkDataButton.setTitle("Next", for: .normal)
            // Cancel the connection.
            connection.cancel()
            didPassNetworkDataSuccessfully = true
        }
        instructionLabel.text = instructionMessage
    }
}
