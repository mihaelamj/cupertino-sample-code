/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implement the view controller that allows the user
        to control a nearby game.
*/

import WatchKit
import Network

class PeerListViewController: WKInterfaceController {
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        // Listen immediately upon startup.
        applicationServiceListener = PeerListener(delegate: self)
    }
}

extension PeerListViewController: PeerConnectionDelegate {
    // When a connection becomes ready, move into game mode.
    func connectionReady() {
        pushController(withName: "showGamePage", context: nil)
    }

    // When you can't advertise the game, show an error
    func displayAdvertiseError(_ error: NWError) {
        let message = "Error \(error)"
        let alertAction = WKAlertAction(title: "OK", style: .default) { () -> Void in
            print("Ok")
        }
        presentAlert(withTitle: "Cannot join game", message: message, preferredStyle: .alert, actions: [alertAction])
    }

    // Ignore connection failures and messages prior to starting a game.
    func connectionFailed() { }
    func receivedMessage(content: Data?, message: NWProtocolFramer.Message) { }
}
