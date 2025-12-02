/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the main UI of the watchOS app.
*/

import SwiftUI
import Combine
import WatchConnectivity

extension NotificationCenter {
    var activationDidCompletePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .activationDidComplete).receive(on: .main)
    }
    var reachabilityDidChangePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .reachabilityDidChange).receive(on: .main)
    }
}

struct ContentView: View {
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var selection: Command = .updateAppContext
    
    let commands: [Command] = [.updateAppContext, .sendMessage, .sendMessageData,
                               .transferFile, .transferUserInfo,
                               .transferCurrentComplicationUserInfo]
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(commands, id: \.self) { command in
                CommandView(command: command, selectedTab: $selection).tag(command)
            }
        }
        .onReceive(NotificationCenter.default.activationDidCompletePublisher) { notification in
            activationDidComplete(notification)
        }
        .onReceive(NotificationCenter.default.reachabilityDidChangePublisher) { notification in
            reachabilityDidChange(notification)
        }
    }
}

extension ContentView {
    /**
     Observe the activation state change and log the current state.
     */
    private func activationDidComplete(_ notification: Notification) {
        print("\(#function): activationState:\(WCSession.default.activationState.rawValue)")
    }
    /**
     Observe the reachability state change and log the current state.
     */
    private func reachabilityDidChange(_ notification: Notification) {
        print("\(#function): isReachable:\(WCSession.default.isReachable)")
    }
}
