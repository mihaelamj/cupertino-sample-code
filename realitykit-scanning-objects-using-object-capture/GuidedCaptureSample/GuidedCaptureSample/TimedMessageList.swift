/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A timed, observable FIFO of messages and modifies property `withAnimation` for use as a ground truth
 source of data for a SwiftUI View.
*/

import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem,
                            category: "TimedMessageList")

/// Use a `TimedMessageList` to add a message to a FIFO for display with some minimum duration. The time can be extended
/// if it gets refreshed. This object will automatically remove items whose timer has expired.
/// Because this is `Observable`, SwiftUI can use it to directly update a `View`.
/// The changes to `messages` are done inside `withAnimation` to allow transitions as well.
@Observable
class TimedMessageList {
    // A `Message` is unique at creation, with identity separate from its actual message string and
    // ending time so that SwiftUI has a consistent identity for animation purposes when time changes.
    // Not tying the identity to the string means the app can duplicate messages in the
    // list with different end times, if desired.
    struct Message: Identifiable {
        // Keep the ID stable for the animation to work properly.
        let id = UUID()
        let message: String
        let startTime: Date
        // Only this implementation can change the `endTime` to maintain a single timer state.
        // Callers need to go through the `TimedMessageList` directly to extend time.
        fileprivate(set) var endTime: Date?

        init(_ msg: String, startTime inStartTime: Date = Date()) {
            message = msg
            startTime = inStartTime
            endTime = nil
        }

        func hasExpired() -> Bool {
            guard let endTime else {
                return false
            }
            return Date() >= endTime
        }
    }

    var activeMessage: Message? = nil

    /// Ordered list of messages added to the list. Updated by public calls to add new elements or refresh the timers on existing
    /// ones. Automatically removes expired messages based on `endTime`.
    private var messages: [Message] = [] {
        didSet {
            dispatchPrecondition(condition: .onQueue(.main))
            let newActiveMsg = !messages.isEmpty ? messages[0] : nil
            if activeMessage?.message != newActiveMsg?.message {
                withAnimation {
                    activeMessage = newActiveMsg
                }
            }
        }
    }

    /// If there are any items in messages, the timer is set to execute on the nearest `endTime`.
    private var timer: Timer?

    private let feedbackMessageMinimumDurationSecs: Double = 2.0

    init() { }

    /// Adds a new message with the given `msg` string.
    ///
    /// - Parameter msg: A string to display for the message.
    func add(_ msg: String) {
        dispatchPrecondition(condition: .onQueue(.main))

        if let index = messages.lastIndex(where: { $0.message == msg }) {
            messages[index].endTime = nil
        } else {
            messages.append(Message(msg))
        }
        setTimer()
    }

    /// Removes the message with the given `msg` string.
    ///
    /// - Parameter msg: A string to display for the message.
    func remove(_ msg: String) {
        dispatchPrecondition(condition: .onQueue(.main))

        guard let index = messages.lastIndex(where: { $0.message == msg }) else { return }
        var endTime = Date()
        let earliestAcceptableEndTime = messages[index].startTime + feedbackMessageMinimumDurationSecs
        if endTime < earliestAcceptableEndTime {
            endTime = earliestAcceptableEndTime
        }
        messages[index].endTime = endTime
        setTimer()
    }

    /// Removes all messages.
    func removeAll() {
        timer?.invalidate()
        timer = nil
        activeMessage = nil
        messages.removeAll()
    }

    /// Sets a timer to execute for the nearest future `endTime`.
    private func setTimer() {
        dispatchPrecondition(condition: .onQueue(.main))

        timer?.invalidate()
        timer = nil

        // Cull expired timers then find the next expiration and make a new timer.
        cullExpired()
        if let nearestEndTime = (messages.compactMap { $0.endTime }).min() {
            let duration = nearestEndTime.timeIntervalSinceNow
            timer = Timer.scheduledTimer(timeInterval: duration,
                                         target: self,
                                         selector: #selector(onTimer),
                                         userInfo: nil,
                                         repeats: false)

        }
    }

    private func cullExpired() {
        dispatchPrecondition(condition: .onQueue(.main))

        withAnimation {
            messages.removeAll(where: { $0.hasExpired() })
        }
    }

    /// Internal callback for the `Timer()`.
    @objc
    private func onTimer() {
        dispatchPrecondition(condition: .onQueue(.main))

        timer?.invalidate()
        cullExpired()
        setTimer()
    }
}
