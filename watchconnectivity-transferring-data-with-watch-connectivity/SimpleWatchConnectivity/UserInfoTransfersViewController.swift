/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages the UserInfo transfer of the iOS app.
*/

import UIKit
import WatchConnectivity

class UserInfoTransfersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var command: Command!
    
    // Outstanding transfers can change in the background, so make a copy (cache) to
    // make sure the data doesn't change during the table view loading cycle.
    // Subclasses can override the computed property to provide the right transfers.
    //
    var transfersStore: [SessionTransfer]?
    var transfers: [SessionTransfer] {

        guard transfersStore == nil else { return transfersStore! }
        
        if command == .transferUserInfo {
            transfersStore = WCSession.default.outstandingUserInfoTransfers.filter {
                $0.isCurrentComplicationInfo == false
            }
            
        } else if command == .transferCurrentComplicationUserInfo {
            transfersStore = WCSession.default.outstandingUserInfoTransfers.filter {
                $0.isCurrentComplicationInfo == true
            }
        }
        return transfersStore!
    }

    // View controller life cycle.
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions handlers.
    //
    @IBAction func dismiss(_ sender: UIButton) {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    @objc
    func cancel(_ sender: UIButton) {
        let buttonOrigin = sender.convert(CGPoint.zero, to: tableView)
        guard let indexPath = tableView.indexPathForRow(at: buttonOrigin) else { return }
        
        let transfer = transfers[indexPath.row]
        transfer.cancel(notifying: command)
    }
    
    // MARK: - Notification handlers.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? CommandStatus else { return }
        
        // Invalidate the cached transfers and reload the table view with animation
        // if the notification command is relevant and isn't failed.
        //
        if commandStatus.command == command, commandStatus.phrase != .failed {
            transfersStore = nil
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
}

extension UserInfoTransfersViewController { // MARK: - UITableViewDelegate, UITableViewDataSource.
    
    private func newAccessoryView(titleColor: UIColor?) -> UIButton {
        let button = UIButton(type: .roundedRect)
        button.setTitle("  X   ", for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(type(of: self).cancel(_:)), for: .touchUpInside)
        return button
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transfers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransferCell", for: indexPath)
        
        let transfer = transfers[indexPath.row]
        cell.accessoryView = newAccessoryView(titleColor: transfer.timedColor.color)
        cell.textLabel?.text = transfer.timedColor.timeStamp
        cell.textLabel?.textColor = transfer.timedColor.color
        cell.detailTextLabel?.text = nil

        return cell
    }
}
