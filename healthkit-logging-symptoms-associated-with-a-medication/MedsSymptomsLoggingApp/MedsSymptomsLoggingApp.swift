/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An app that contains all visible content.
*/

import HealthKit
import SwiftUI

@main
struct MedsSymptomsLoggingApp: App {
    private let healthStore = HealthStore.shared.healthStore

    @State var triggerMedicationsAuthorization: Bool = false
    @State var healthDataAuthorized: Bool?

    var body: some Scene {
        WindowGroup {
            TabsView(toggleHealthDataAuthorization: $triggerMedicationsAuthorization,
                     healthDataAuthorized: $healthDataAuthorized)
            .onAppear {
                triggerMedicationsAuthorization.toggle()
            }
            .healthDataAccessRequest(store: healthStore,
                                     objectType: .userAnnotatedMedicationType(),
                                     trigger: triggerMedicationsAuthorization,
                                     completion: { @Sendable result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        healthDataAuthorized = true
                    case .failure(let error):
                        print("Error when requesting HealthKit read authorizations: \(error)")
                    }
                }
            })
        }
    }
}
