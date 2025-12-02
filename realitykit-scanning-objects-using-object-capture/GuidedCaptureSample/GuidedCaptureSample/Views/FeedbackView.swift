/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for displaying the feedback messages for scanning.
*/

import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem,
                            category: "FeedbackView")

struct FeedbackView: View {
    var messageList: TimedMessageList

    var body: some View {
        VStack {
            if let activeMessage = messageList.activeMessage {
                Text("\(activeMessage.message)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .environment(\.colorScheme, .dark)
                    .transition(.opacity)
            }
        }
    }
}
