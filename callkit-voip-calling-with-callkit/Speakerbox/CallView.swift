/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The call view.
*/

import SwiftUI

struct CallView: View {

    static let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    static let callDurationFormatter: DateComponentsFormatter = {
        let dateFormatter: DateComponentsFormatter
        dateFormatter = DateComponentsFormatter()
        dateFormatter.unitsStyle = .positional
        dateFormatter.allowedUnits = [.minute, .second]
        dateFormatter.zeroFormattingBehavior = .pad

        return dateFormatter
    }()

    @EnvironmentObject var callsController: SpeakerboxCallManager
    @ObservedObject var call: SpeakerboxCall
    @State private var formattedCallDuration: Text?
    @State private var isShowingActions = false

    var body: some View {
        Button(action: { self.isShowingActions = true }) {
            VStack {
                HStack {
                    Text(call.handle ?? "-")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()
                }

                HStack {
                    callStatus
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    formattedCallDuration
                        .font(Font.subheadline.monospacedDigit())
                        .foregroundColor(.secondary)
                        .onReceive(CallView.timer) { _ in
                            self.updateFormattedCallDuration()
                        }
                }
            }
            .lineLimit(1)
            .padding(.vertical, 8.0)
        }
        .actionSheet(isPresented: $isShowingActions) {
            ActionSheet(title: Text("Call Action"), message: nil, buttons: [
                .destructive(Text("End Call"), action: {
                    self.callsController.end(call: self.call)
                }),
                .default(Text("Toggle Hold"), action: {
                    self.callsController.setOnHoldStatus(for: self.call, to: !self.call.isOnHold)
                }),
                .cancel()])
        }
    }

    /// Returns a Text view with the current call status.
    var callStatus: some View {
        let text: String

        if call.hasConnected {
            text = call.isOnHold ? "On Hold" : "Active"
        } else if call.hasStartedConnecting {
            text = "Connecting…"
        } else {
            text = call.isOutgoing ? "Dialing…" : "Ringing…"
        }

        return Text(text)
    }

    /// Updates the the formatted call duration Text view for an active call's current duration, otherwise sets it to `nil`.
    func updateFormattedCallDuration() {
        if call.hasConnected, let formattedString = CallView.callDurationFormatter.string(from: call.duration) {
            formattedCallDuration = Text(formattedString)
        } else {
            formattedCallDuration = nil
        }
    }

}
