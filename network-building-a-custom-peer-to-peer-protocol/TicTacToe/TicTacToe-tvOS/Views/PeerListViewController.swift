/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implement the view controller that allows the user
        to find a nearby device to play the game.
*/

import UIKit
import Network
import DeviceDiscoveryUI

class PeerListViewController: UITableViewController {
    var sections: [GameFinderSection] = [.host]

    enum GameFinderSection {
        case host
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "joinGameCell")
    }

    func hostGameButton() async {
        // Check to see whether the device supports DDDevicePickerViewController.
        guard DDDevicePickerViewController.isSupported(.applicationService(name: "TicTacToe"),
                                                                           using: applicationServiceParameters()) else {
            print("This device does not support DDDevicePickerViewController.")
            return
        }

        // Create the view controller for the device picker.
        guard let devicePicker = DDDevicePickerViewController(browseDescriptor: .applicationService(name: "TicTacToe"),
                                                              parameters: applicationServiceParameters()) else {
            print("Could not create device picker.")
            return
        }
        
        // Show the network device picker as a full-screen, modal view.
        self.present(devicePicker, animated: true)
        
        do {
            // Receive an endpoint asynchronously.
            let endpoint = try await devicePicker.endpoint
            sharedConnection = PeerConnection(endpoint: endpoint, delegate: self)
       } catch let error {
           // Handle any errors.
           print("There was an error with the endpointPicker: \(error)")
       }
    }
    
    func hostGameButton() {
        Task {
            await hostGameButton()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let currentSection = sections[section]
        switch currentSection {
        case .host:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let currentSection = sections[section]
        switch currentSection {
        case .host:
            return "Host Game"
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentSection = sections[indexPath.section]
        switch currentSection {
        case .host:
            if indexPath.row == 0 {
                hostGameButton()
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PeerListViewController: PeerConnectionDelegate {
    // When a connection becomes ready, move into game mode.
    func connectionReady() {
        navigationController?.performSegue(withIdentifier: "showGameSegue", sender: nil)
    }

    // Ignore connection failures and messages prior to starting a game.
    func displayAdvertiseError(_ error: NWError) { }
    func connectionFailed() { }
    func receivedMessage(content: Data?, message: NWProtocolFramer.Message) { }
}
