/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays an incrementing timer.
*/

import SwiftUI

/// A timer view that counts up from a start date.
///
/// If the start date is `nil`, the view displays `0:00`.
struct TimerView: View {

    /// The date from which the timer counts up.
    var startDate: Date?

    private var interval: ClosedRange<Date> {
        if let startDate {
            return (startDate...Date.distantFuture)
        } else {
            return (Date.distantPast...Date.distantFuture)
        }
    }

    private var pauseTime: Date? {
        (startDate != nil) ? nil : .distantPast
    }

    private var fillColor: Color {
        (startDate != nil) ? .red : .black.opacity(0.5)
    }

    var body: some View {
        Text(timerInterval: interval, pauseTime: pauseTime, countsDown: false, showsHours: true)
            .foregroundColor(.white)
            .fontDesign(.monospaced)
            .fontWeight(.semibold)
            .padding(3)
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .fill(fillColor)
            }
    }
}

// MARK: -

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TimerView(startDate: nil)
            TimerView(startDate: .now.addingTimeInterval(-1000))
            TimerView(startDate: .now.addingTimeInterval(0))
            TimerView(startDate: .now.addingTimeInterval(10_000))
        }
    }
}
