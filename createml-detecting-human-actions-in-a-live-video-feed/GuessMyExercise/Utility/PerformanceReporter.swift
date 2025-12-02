/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The performance reporter prints the number of frames and predictions every
 second. This is a "nice to have" feature the app doesn't need to function.
*/

import Foundation

/// Prints performance information to the console once per second.
///
/// The reporter prints the number of frames and predictions in the last second.
class PerformanceReporter {
    /// A Boolean that indicates whether to print the performance numbers.
    static let isEnabled = true

    /// Defines each report's index number, starting with one.
    private var reportIndex = 0

    /// The number of frames in the performance report.
    private var frameCount = 0

    /// The number of action predictions in the performance report.
    private var predictionCount = 0

    /// A timer that fires once per second.
    private var repeatingTimer: Timer?

    init?() {
        guard PerformanceReporter.isEnabled else { return nil }

        let timer = Timer(timeInterval: 1.0,
                          repeats: true) { [unowned self] _ in
            self.reportToConsole()
        }

        // Set this timer to fire on all runloop modes.
        RunLoop.current.add(timer, forMode: .common)

        repeatingTimer = timer
    }

    /// Disables and releases the repeating timer.
    deinit { repeatingTimer?.invalidate() }

    /// Adds one to the frame count.
    func incrementFrameCount() { frameCount += 1 }

    /// Adds one to the prediction count.
    func incrementPrediction() { predictionCount += 1 }

    /// Prints the frame and prediction counts to the console.
    private func reportToConsole() {
        guard  PerformanceReporter.isEnabled else { return }
        reportIndex += 1

        let report = "#\(reportIndex):"
            + " \(predictionCount) action predictions"
            + " across \(frameCount) frames."

        // Prepare for the next report.
        frameCount = 0
        predictionCount = 0

        print(report)

    }
}
