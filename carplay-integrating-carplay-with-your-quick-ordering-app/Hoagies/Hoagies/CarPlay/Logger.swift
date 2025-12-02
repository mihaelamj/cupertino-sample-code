/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Methods that handle the logging of events during a CarPlay session.
*/

import Foundation
import SwiftUI

struct Event: Hashable, Identifiable {
    let date: Date = Date()
    let text: String!
    let id = UUID()
}

/**
 `Logger` describes an object that can receive interesting events from elsewhere in the app,
 and persist them to memory, disk, a network connection, or elsewhere.
 */
protocol Logger {
    /// Append a new event to the log. The system adds all events at the 0 index.
    func appendEvent(_: String)
    
    /// Fetch the list of events that this logger receives.
    var events: [Event] { get }
}

/**
 `MemoryLogger` is a type of `Logger` that records events in-memory for the current life cycle of the app.
 */
@Observable class MemoryLogger: Logger {
    
    static let shared = MemoryLogger()
    
    public private(set)var events: [Event]
    
    private let loggingQueue: OperationQueue
    
    private init() {
        events = []
        loggingQueue = OperationQueue()
        loggingQueue.maxConcurrentOperationCount = 1
        loggingQueue.name = "Memory Logger Queue"
        loggingQueue.qualityOfService = .userInitiated
    }
    
    func appendEvent(_ event: String) {
        loggingQueue.addOperation {
            DispatchQueue.main.async {
                self.events.insert(Event(text: event), at: 0)
            }
        }
    }
}
