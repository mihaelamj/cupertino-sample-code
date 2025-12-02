/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the WCSessionDelegate methods.
*/

import Foundation
import WatchConnectivity
import WidgetKit

// Custom notifications happen when Watch Connectivity activation or reachability status changes,
// or when receiving or sending data. Clients observe these notifications to update the UI.
//
extension Notification.Name {
    static let dataDidFlow = Notification.Name("DataDidFlow")
    static let activationDidComplete = Notification.Name("ActivationDidComplete")
    static let reachabilityDidChange = Notification.Name("ReachabilityDidChange")
}

// Implement WCSessionDelegate methods to receive Watch Connectivity data and notify clients.
// Handle WCSession status changes.
//
class SessionDelegator: NSObject, WCSessionDelegate {
    
    // Monitor WCSession activation state changes.
    //
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        postNotificationOnMainQueueAsync(name: .activationDidComplete)
    }
    
    // Monitor WCSession reachability state changes.
    //
    func sessionReachabilityDidChange(_ session: WCSession) {
        postNotificationOnMainQueueAsync(name: .reachabilityDidChange)
    }
    
    // Did receive an app context.
    //
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        var commandStatus = CommandStatus(command: .updateAppContext, phrase: .received)
        commandStatus.timedColor = TimedColor(applicationContext)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Did receive a message, and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        var commandStatus = CommandStatus(command: .sendMessage, phrase: .received)
        commandStatus.timedColor = TimedColor(message)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Did receive a message, and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        self.session(session, didReceiveMessage: message)
        replyHandler(message) // Echo back the time stamp.
    }
    
    // Did receive a piece of message data, and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        var commandStatus = CommandStatus(command: .sendMessageData, phrase: .received)
        commandStatus.timedColor = TimedColor(messageData)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Did receive a piece of message data, and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        self.session(session, didReceiveMessageData: messageData)
        replyHandler(messageData) // Echo back the time stamp.
    }
    
    // Did receive a piece of userInfo.
    //
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        var commandStatus = CommandStatus(command: .transferUserInfo, phrase: .received)
        commandStatus.timedColor = TimedColor(userInfo)
        
        guard let isComplicationInfo = userInfo[PayloadKey.isCurrentComplicationInfo] as? Bool,
              isComplicationInfo == true else {
            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
            return
        }
                    
        #if os(watchOS)
        commandStatus.command = .transferCurrentComplicationUserInfo
        
        guard let sharedUserDefaults = UserDefaults(suiteName: WidgetSupport.appGroupContainer) else {
            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
            return
        }
        // Persist the data to the app group container.
        //
        sharedUserDefaults.setValue(commandStatus.timedColor?.timeStamp, forKey: WidgetSupport.UserDefaultsKey.timestamp)
        sharedUserDefaults.setValue(commandStatus.timedColor?.colorData, forKey: WidgetSupport.UserDefaultsKey.colorData)
        
        // Reload the timeline of the widget, if necessary.
        //
        WidgetCenter.shared.getCurrentConfigurations { result in
            switch result {
            case .success(let widgetInfoList):
                for widgetInfo in widgetInfoList where widgetInfo.kind == WidgetSupport.widgetKind {
                    WidgetCenter.shared.reloadTimelines(ofKind: widgetInfo.kind)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
        #endif
    }
    
    // Did finish sending a piece of userInfo.
    //
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        var commandStatus = CommandStatus(command: .transferUserInfo, phrase: .finished)
        commandStatus.timedColor = TimedColor(userInfoTransfer.userInfo)
        
        #if os(iOS)
        if userInfoTransfer.isCurrentComplicationInfo {
            commandStatus.command = .transferCurrentComplicationUserInfo
        }
        #endif

        if let error = error {
            commandStatus.errorMessage = error.localizedDescription
        }
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Did receive a file.
    //
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        var commandStatus = CommandStatus(command: .transferFile, phrase: .received)
        commandStatus.file = file
        commandStatus.timedColor = TimedColor(file.metadata!)
        
        // The system removes WCSessionFile.fileURL once this method returns,
        // so dispatch to main queue synchronously instead of calling
        // postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo).
        //
        DispatchQueue.main.sync {
            NotificationCenter.default.post(name: .dataDidFlow, object: commandStatus)
        }
    }
    
    // Did finish a file transfer.
    //
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        var commandStatus = CommandStatus(command: .transferFile, phrase: .finished)

        if let error = error {
            commandStatus.errorMessage = error.localizedDescription
            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
            return
        }
        commandStatus.fileTransfer = fileTransfer
        commandStatus.timedColor = TimedColor(fileTransfer.file.metadata!)

        #if os(watchOS)
        Logger.shared.clearLogs()
        #endif
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // WCSessionDelegate methods for iOS only.
    //
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    #endif
    
    // Post a notification on the main thread asynchronously.
    //
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }
}
