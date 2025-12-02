/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays active and archived user-authorized medications.
*/

import SwiftUI
import UIKit

struct MedicationListView: View {

    @State private var medicationProvider = MedicationProvider()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Section(header: Text("Active Medications")
                    .textCase(nil)
                    .font(.title3)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .padding(4)
                ) {
                    ForEach(medicationProvider.activeMedicationConcepts) { concept in
                        MedicationView(annotatedMedicationConcept: concept,
                                       doseEventProvider: DoseEventProvider(healthStore: HealthStore.shared.healthStore,
                                                                            annotatedMedicationConcept: concept))
                        .environment(medicationProvider)
                    }
                }

                Section(header: Text("Archived Medications")
                    .textCase(nil)
                    .font(.title3)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .padding(4)
                ) {
                    if medicationProvider.archivedMedicationConcepts.isEmpty {
                        Text("Unable to find archived medications.")
                            .padding()
                    } else {
                        ForEach(medicationProvider.archivedMedicationConcepts) { concept in
                            ArchivedMedicationView(annotatedMedicationConcept: concept,
                                                   doseEventProvider: DoseEventProvider(healthStore: HealthStore.shared.healthStore,
                                                                                        annotatedMedicationConcept: concept))
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                Task {
                    /// Fetch medication data each time.
                    await medicationProvider.loadDataFromHealthKit()
                }
            }
        }
    }
}
