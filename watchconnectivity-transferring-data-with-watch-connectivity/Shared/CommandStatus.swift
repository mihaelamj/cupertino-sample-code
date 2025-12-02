/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Wraps the command status.
*/

import UIKit
import WatchConnectivity

// Constants to identify the Watch Connectivity methods, also for user-visible strings in UI.
//
enum Command: String {
    case updateAppContext = "UpdateAppContext"
    case sendMessage = "SendMessage"
    case sendMessageData = "SendMessageData"
    case transferUserInfo = "TransferUserInfo"
    case transferFile = "TransferFile"
    case transferCurrentComplicationUserInfo = "TransferComplicationUserInfo"
}

// Constants to identify the phrases of Watch Connectivity communication.
//
enum Phrase: String {
    case updated = "Updated"
    case sent = "Sent"
    case received = "Received"
    case replied = "Replied"
    case transferring = "Transferring"
    case canceled = "Canceled"
    case finished = "Finished"
    case failed = "Failed"
}

// Wrap a timed color payload dictionary with a stronger type.
//
struct TimedColor {
    var timeStamp: String
    var colorData: Data
    
    var color: UIColor {
        let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIColor.self], from: colorData)
        guard let color = uiColor as? UIColor else {
            fatalError("Failed to unarchive a UIClor object!")
        }
        return color
    }
    var timedColor: [String: Any] {
        return [PayloadKey.timeStamp: timeStamp, PayloadKey.colorData: colorData]
    }
    
    init(_ timedColor: [String: Any]) {
        guard let timeStamp = timedColor[PayloadKey.timeStamp] as? String,
            let colorData = timedColor[PayloadKey.colorData] as? Data else {
                fatalError("Timed color dictionary doesn't have right keys!")
        }
        self.timeStamp = timeStamp
        self.colorData = colorData
    }
    
    init(_ timedColor: Data) {
        let data = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSString.self, NSData.self], from: timedColor)
        guard let dictionary = data as? [String: Any] else {
            fatalError("Failed to unarchive a timedColor dictionary!")
        }
        self.init(dictionary)
    }
}

// Wrap the command's status to bridge the commands status and UI.
//
struct CommandStatus {
    var command: Command
    var phrase: Phrase
    var timedColor: TimedColor?
    var fileTransfer: WCSessionFileTransfer?
    var file: WCSessionFile?
    var userInfoTranser: WCSessionUserInfoTransfer?
    var errorMessage: String?
    
    init(command: Command, phrase: Phrase) {
        self.command = command
        self.phrase = phrase
    }
}
