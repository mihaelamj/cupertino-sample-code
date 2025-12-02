/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model for the content view.
*/
import CoreMotion
import SwiftUI
import os.log

final class ContentViewState: ObservableObject {

    fileprivate var headphoneActivityManager = CMHeadphoneActivityManager()

    @Published var activity: String = "Not started"
    @Published var isEnabled: Bool = false {
        didSet {
            if self.isEnabled {
                self.startUpdating()
            } else {
                self.stopUpdating()
            }
        }
    }

    deinit {
        self.stopUpdating()
    }

    // Returns a human-readable description of the activity.
    private func activityHumanReadableDescription(_ activity: CMMotionActivity) -> String {
        if activity.unknown {
            return "Unknown"
        }
        if activity.stationary {
            return "Stationary"
        }
        if activity.walking {
            return "Walking"
        }
        if activity.running {
            return "Running"
        }
        if activity.automotive {
            return "Automotive"
        }
        if activity.cycling {
            return "Cycling"
        }
        return "Other Moving"
    }

    // Starts listening for activity changes.
    private func startUpdating() {
        if !self.headphoneActivityManager.isActivityAvailable {
            os_log(.error, "Headphone activity is not available!")
            return
        }
        self.headphoneActivityManager.startActivityUpdates(to: OperationQueue.main) {
            activity, error in
            if error != nil {
                os_log(.error, "Couldn't get activity update: %{public}", error!.localizedDescription)
                return
            }
            // Publish the activity.
            self.activity = self.activityHumanReadableDescription(activity!)
        }
    }

    // Stops listening for activity changes.
    private func stopUpdating() {
        self.headphoneActivityManager.stopActivityUpdates()
        self.activity = "Not started"
    }

}
