/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller that displays the QR code and the decoded information from the QR code.
*/

import Cocoa
import Network
import CoreWLAN

final class BrandXAccessoryConfigureViewController: BrandXAccessoryBaseViewController {
    
    // MARK: - @IBOutlet variables
    
    @IBOutlet private weak var qrCodeImageView: NSImageView!
    @IBOutlet private weak var ssidValue: NSTextField!
    @IBOutlet private weak var passphraseValue: NSTextField!
    @IBOutlet private weak var serviceNameValue: NSTextField!
    @IBOutlet private weak var pskValue: NSTextField!
    @IBOutlet private weak var pskIdentityValue: NSTextField!
    @IBOutlet private weak var listenerUpdate: NSTextField!
    
    // MARK: - Private Variables
    
    private var urlComponents = URLComponents()
    
    // MARK: - Public Variables
    
    public var websocketConnection: WebSocketConnection?
    
    // MARK: - Private Constants
    
    private let psk: String = ConfigurationUtility.createRandomString(length: 20)
    private let pskIdentity: String = ConfigurationUtility.createRandomString(length: 10)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlComponents.scheme = "wss"
        urlComponents.port = Int(Constants.port)
        
        qrCodeImageView.layer?.backgroundColor = .black
        ssidValue.stringValue = Constants.accessorySSID
        passphraseValue.stringValue = Constants.accessoryPassphrase
        pskValue.stringValue = psk
        pskIdentityValue.stringValue = pskIdentity
        
        // Update the status label.
        updateStatusLabel()
        
        // Attempt to set the IP address when entering the view controller for display in the UI.
        ConfigurationUtility.getIPAddress { ipAddr in
            DispatchQueue.main.async {
                // Notice the prepended WebSocket secure protocol.
                self.urlComponents.host = "\(ipAddr)"
                self.serviceNameValue.stringValue = "\(self.urlComponents.scheme!)://\(self.urlComponents.host!):\(self.urlComponents.port!)"
                self.updateQRCode()
            }
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func backButton(sender: AnyObject) {
        if let setupVC = storyBoard.instantiateController(withIdentifier: "SetupViewController") as? BrandXAccessorySetupViewController {
            if let window = view.window {
                WebSocketListener.shared.cancelListener()
                setupVC.view.frame = CGRect(origin: .zero, size: window.frame.size)
                window.contentViewController = setupVC
            }
        }
    }
    
    @IBAction func startListenerButton(sender: AnyObject) {
        
        // If the listener is already started, don’t start it.
        if WebSocketListener.shared.listenerDidStart {
            return
        }
        
        WebSocketListener.shared.delegate = self
        WebSocketListener.shared.startListener(psk: psk, pskIdentity: pskIdentity)
    }
    
    // MARK: - Instance Methods
    
    func navigateToNextScreen(receivedMessage: WebSocketMessage) {
        if let doneVC = storyBoard.instantiateController(withIdentifier: "DoneViewController") as? BrandXAccessoryDoneViewController {
            if let window = view.window {
                doneVC.acquiredSSID = receivedMessage.ssid
                doneVC.acquiredPassphrase = receivedMessage.passphrase
                doneVC.view.frame = CGRect(origin: .zero, size: window.frame.size)
                view.window?.contentViewController = doneVC
            }
        }
    }
    
    func updateQRCode() {
        
        if pskIdentity.isEmpty {
            listenerUpdate.stringValue = "Listener failed, no authentication code"
            return
        }
        
        let accessoryNetwork = AccessoryNetwork(accessorySSID: Constants.accessorySSID, accessoryPassphrase: Constants.accessoryPassphrase,
                                                scheme: urlComponents.scheme!, host: urlComponents.host!,
                                                port: String(urlComponents.port!), psk: psk, pskIdentity: pskIdentity)
        
        // Generate a QR code with the encoded string above.
        if let ciImage = ConfigurationUtility.generateQRCode(networkInfo: accessoryNetwork.qrCodeString, to: 144.0, and: 144.0) {
            let representation = NSCIImageRep(ciImage: ciImage)
            let image = NSImage(size: NSSize(width: 144.0, height: 144.0))
            image.addRepresentation(representation)
            qrCodeImageView.image = image
        }
    }
    
    func updateStatusLabel() {
        if CWWiFiClient.shared().interface()?.interfaceMode() == .some(.hostAP) {
            status = "Internet Sharing Started"
        } else {
            status = "Internet Sharing NOT Started"
        }
        
        if WebSocketListener.shared.listenerDidStart {
            status += ", Listener is Started"
            listenerUpdate.stringValue = "Listener - ready on port \(WebSocketListener.shared.listenerPort)"
        } else {
            status += ", Listener is NOT Started"
        }
    }
}

// MARK: - WebSocketListenerDelegate Methods

/// The Extension for receiving WebSocket listener updates, that is, the listener starts and a new connection occurs.
extension BrandXAccessoryConfigureViewController: WebSocketListenerDelegate {
    
    // Set the listener updates.
    func didReceiveListenerUpdate(listener: WebSocketListener, didUpdateMessage: String) {
        // Keep in mind that the listener can fail here, which is ok.
        // If the listener fails, this indicates something else that needs attention.
        listenerUpdate.stringValue = didUpdateMessage
        updateStatusLabel()
    }
    
    // Start a new WebSocketConnection for the new connection from the listener.
    func didReceiveNewConnection(listener: WebSocketListener, newConnection: NWConnection) {
        // If a new connection comes in while an existing connection is ready, return.
        guard websocketConnection == nil else {
            return
        }
        
        let webSocket = WebSocketConnection(newConnection: newConnection)
        websocketConnection = webSocket
        webSocket.delegate = self
        webSocket.startConnection()
    }
}

// MARK: - WebSocketConnectionDelegate Methods

/// The Extension for receiving WebSocket connection updates.
extension BrandXAccessoryConfigureViewController: WebSocketConnectionDelegate {
    
    /// Add status updates according to the status of the WebSocketConnection.
    func didEstablishConnection(connection: WebSocketConnection, with error: Error?) {
        // Perform connection establishment logic here.
        if let connectionError = error {
            print("Connection Did Error: \(connectionError.localizedDescription)")
            websocketConnection = nil
        }
    }
    
    /// Check that the data you’re receiving is the network information, and ACK it.
    func didReceivedData(connection: WebSocketConnection, with receivedMessage: WebSocketMessage) {
        // Check for the incoming SSID.
        guard !receivedMessage.ssid.isEmpty, !receivedMessage.passphrase.isEmpty else {
            print("SSID and Passphrase cannot be empty")
            return
        }
        
        var ackMesage = receivedMessage
        ackMesage.status = "ACK"
        // Make sure iOS knows when the accessory receives the network information.
        connection.sendDataOnConnection(websocketMessage: ackMesage)
        WebSocketListener.shared.cancelListener() // There's no need to listen for new connections.
        // Navigate to the next screen.
        navigateToNextScreen(receivedMessage: ackMesage)
    }
}
