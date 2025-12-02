/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The commands view controller of the iOS app.
*/

import UIKit
import WatchConnectivity

class CommandsViewController: UITableViewController, TestDataProvider, SessionCommands {

    // List the supported methods, shown in the main table.
    //
    let commands: [Command] = [.updateAppContext, .sendMessage, .sendMessageData,
                               .transferFile, .transferUserInfo,
                               .transferCurrentComplicationUserInfo]
    
    var currentCommand: Command = .updateAppContext // Default to .updateAppContext.
    var currentColor: UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 42

        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // .dataDidFlow notification handler. Update the UI with the notification object.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
        if let commandStatus = notification.object as? CommandStatus {
            currentCommand = commandStatus.command
            currentColor = commandStatus.timedColor?.color
            tableView.reloadData()
        }
    }
}

extension CommandsViewController { // MARK: - UITableViewDelegate and UITableViewDataSoruce.
    
    // Create a button for the specified command and with the title color.
    // The button is used as the accessory view of the table cell.
    //
    private func newAccessoryView(cellCommand: Command, titleColor: UIColor?) -> UIButton {
        var transferCount = 0
        
        // Retrieve the transfer count for the command.
        //
        if cellCommand == .transferFile {
            transferCount = WCSession.default.outstandingFileTransfers.count
            
        } else if cellCommand == .transferUserInfo {
            let transfers = WCSession.default.outstandingUserInfoTransfers.filter {
                $0.isCurrentComplicationInfo == false
            }
            transferCount = transfers.count
            
        } else if cellCommand == .transferCurrentComplicationUserInfo {
            let transfers = WCSession.default.outstandingUserInfoTransfers.filter {
                $0.isCurrentComplicationInfo == true
            }
            transferCount = transfers.count
        }
        
        // Create and configure the button.
        //
        let button = UIButton(type: .roundedRect)
        button.addTarget(self, action: #selector(type(of: self).showTransfers(_:)), for: .touchUpInside)
        button.setTitleColor(titleColor, for: .normal)
        button.setTitle(" \(transferCount) ", for: .normal)
        button.sizeToFit()
        return button
    }
    
    // Action handler of the accessory view. Present the view controller for the current command.
    //
    @objc
    private func showTransfers(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint.zero, to: tableView)
        guard let indexPath = tableView.indexPathForRow(at: buttonPosition) else { return }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let command = commands[indexPath.row]
        
        var childViewController: UIViewController
        
        if command == .transferFile {
            let viewController = storyboard.instantiateViewController(withIdentifier: "FileTransfersViewController")
            guard let transfersViewController = viewController as? FileTransfersViewController else {
                fatalError("View controller (FileTransfersViewController) deson't have a right class!")
            }
            transfersViewController.command = command
            childViewController = transfersViewController
            
        } else { //if command == .transferUserInfo || command == .transferCurrentComplicationUserInfo {
            
            let viewController = storyboard.instantiateViewController(withIdentifier: "UserInfoTransfersViewController")
            guard let transfersViewController = viewController as? UserInfoTransfersViewController else {
                fatalError("View controller (UserInfoTransfersViewController) deson't have a right class!")
            }
            transfersViewController.command = command
            childViewController = transfersViewController
        }
        
        addChild(childViewController)
        childViewController.view.frame = view.convert(tableView.bounds, from: tableView)
        view.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
    }

    // UITableViewDelegate and UITableViewDataSource.
    //
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commands.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommandCell", for: indexPath)
        
        let cellCommand = commands[indexPath.row]
        cell.textLabel?.text = cellCommand.rawValue
        
        let textColor: UIColor? = cellCommand == currentCommand ? currentColor : nil
        cell.textLabel?.textColor = textColor
        cell.detailTextLabel?.textColor = textColor
        
        cell.detailTextLabel?.text = nil
        cell.accessoryView = nil
        
        if [.transferFile, .transferCurrentComplicationUserInfo, .transferUserInfo].contains(cellCommand) {
            cell.accessoryView = newAccessoryView(cellCommand: cellCommand, titleColor: textColor)
        }
        
        return cell
    }
    
    // Do the command associated with the selected table row.
    //
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        currentCommand = commands[indexPath.row]
        switch currentCommand {
        case .updateAppContext: updateAppContext(appContext)
        case .sendMessage: sendMessage(message)
        case .sendMessageData: sendMessageData(messageData)
        case .transferUserInfo: transferUserInfo(userInfo)
        case .transferFile: transferFile(file, metadata: fileMetaData)
        case .transferCurrentComplicationUserInfo: transferCurrentComplicationUserInfo(currentComplicationInfo)
        }
    }
}

