/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines the interface for providing payload for Watch Connectivity APIs.
*/

import UIKit

// Constants to access the payload dictionary.
// isCurrentComplicationInfo tells if the userInfo is from transferCurrentComplicationUserInfo
// in session:didReceiveUserInfo: (see SessionDelegator).
//
struct PayloadKey {
    static let timeStamp = "timeStamp"
    static let colorData = "colorData"
    static let isCurrentComplicationInfo = "isCurrentComplicationInfo"
}

// Define the interfaces for providing payload for Watch Connectivity APIs.
// MainViewController and MainInterfaceController adopt this protocol.
//
protocol TestDataProvider {
    var appContext: [String: Any] { get }
    
    var message: [String: Any] { get }
    var messageData: Data { get }
    
    var userInfo: [String: Any] { get }
    
    var file: URL { get }
    var fileMetaData: [String: Any] { get }
}

// Generate the default payload for commands. The payload contains a random color and a time stamp.
//
extension TestDataProvider {
    
    // Generate a dictionary containing a time stamp and a random color data.
    //
    private func timedColor() -> [String: Any] {
        let red = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let green = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let blue = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        
        let randomColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
        
        let data = try? NSKeyedArchiver.archivedData(withRootObject: randomColor, requiringSecureCoding: false)
        guard let colorData = data else { fatalError("Failed to archive a UIColor!") }
    
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        let timeString = dateFormatter.string(from: Date())
        
        return [PayloadKey.timeStamp: timeString, PayloadKey.colorData: colorData]
    }
    
    // Generate an app context for updateApplicationContext.
    //
    var appContext: [String: Any] {
        return timedColor()
    }
    
    // Generate a message for sendMessage.
    //
    var message: [String: Any] {
        return timedColor()
    }
    
    // Generate a piece of message data for sendMessageData.
    //
    var messageData: Data {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: timedColor(), requiringSecureCoding: false)
        guard let timedColor = data else { fatalError("Failed to archive a timedColor dictionary!") }
        return timedColor
    }
    
    // Generate a userInfo dictionary for transferUserInfo.
    //
    var userInfo: [String: Any] {
        return timedColor()
    }
    
    // Generate a file URL for transferFile.
    // Use the log file for transferFile from the watch side.
    //
    var file: URL {
        #if os(watchOS)
        return Logger.shared.getFileURL() // Use the log file for transferFile.
        #else
        // Use Info.plist for file transfer.
        // Change this to a bigger file to make the file transfer progress more obvious.
        //
        guard let url = Bundle.main.url(forResource: "Info", withExtension: "plist") else {
            fatalError("Failed to find Info.plist in current bundle!")
        }
        return url
        #endif
    }

    // Generate a file metadata dictionary, used as the payload for transferFile.
    //
    var fileMetaData: [String: Any] {
        return timedColor()
    }
    
    // Generate a complication info dictionary for transferCurrentComplicationUserInfo.
    //
    var currentComplicationInfo: [String: Any] {
        var complicationInfo = timedColor()
        complicationInfo[PayloadKey.isCurrentComplicationInfo] = true
        return complicationInfo
    }
}
