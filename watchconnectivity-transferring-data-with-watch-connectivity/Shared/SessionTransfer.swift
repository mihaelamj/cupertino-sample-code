/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines the session transfer interface.
*/

import Foundation
import WatchConnectivity

// Provide a unified interface for transfers. The UI uses this interface to manage transfers.
//
protocol SessionTransfer {
    var timedColor: TimedColor { get }
    var isTransferring: Bool { get }
    func cancel()
    func cancel(notifying command: Command)
}

// Implement the cancel method to cancel the transfer and notify the UI.
//
extension SessionTransfer {
    func cancel(notifying command: Command) {
        var commandStatus = CommandStatus(command: command, phrase: .canceled)
        commandStatus.timedColor = timedColor
        
        cancel()
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        commandStatus.timedColor?.timeStamp = dateFormatter.string(from: Date())
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dataDidFlow, object: commandStatus)
        }
    }
}

// Conform SessionTransfer, and provide a timed color.
//
extension WCSessionUserInfoTransfer: SessionTransfer {
    var timedColor: TimedColor { return TimedColor(userInfo) }
}

// Conform SessionTransfer, and provide a timed color.
//
extension WCSessionFileTransfer: SessionTransfer {
    var timedColor: TimedColor { return TimedColor(file.metadata!) }
}
