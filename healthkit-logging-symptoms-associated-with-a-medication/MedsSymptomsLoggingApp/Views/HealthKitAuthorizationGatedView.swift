/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A file with views that gate content based on authorization.
*/

import HealthKit
import HealthKitUI
import SwiftUI

/// A view that handles requesting HealthKit data access, and gates the display of `contentView` on successful authorization.
struct HealthKitAuthorizationGatedView<ContentView: View>: View {
    let contentView: ContentView

    @Binding var authorized: Bool?

    init(authorized: Binding<Bool?>, @ViewBuilder contentView: () -> ContentView) {
        self._authorized = authorized
        self.contentView = contentView()
    }

    var body: some View {
        VStack {
            switch authorized {
            case nil: ProgressView()
            case .some(true): contentView
            case .some(false):
                if HKHealthStore.isHealthDataAvailable() {
                    Text("Health data access isn't authorized.")
                } else {
                    Text("Health data isn't available on this device.")
                }
            }
        }
    }
}
