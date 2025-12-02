/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the most-recent `DoseEvent` for a selected medication.
*/

import HealthKit
import SwiftUI

struct DoseEventView: View {

    @Environment(MedicationProvider.self) private var medicationProvider
    var annotatedMedicationConcept: AnnotatedMedicationConcept

    @State private var medicationSideEffects: [SymptomModel] = []
    @State private var latestDoseEvent: DoseEventModel?

    @State var doseEventProvider: DoseEventProvider

    @State private var triggerSymptomAuthorization: Bool = false
    @AppStorage("healthSymptomDataAuthorized") private var healthSymptomDataAuthorized: Bool = false
    private let healthStore = HealthStore.shared.healthStore

    private let symptomTypes = Set(symptomTypeIdentifiers.compactMap {
        HKCategoryType.categoryType(forIdentifier: $0)
    })

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Dose")
                    .font(.title)
                    .fontDesign(.rounded)
                    .bold()
                    .padding(.horizontal)
                if let latestDoseEvent = doseEventProvider.lastDoseLogged {
                    ZStack {
                        Rectangle()
                            .fill(Color.yellow)
                            .cornerRadius(15.0)
                            .padding(.horizontal)
                            .frame(height: 100)
                        HStack {
                            Image(systemName: "pills.circle")
                                .foregroundStyle(.orange)
                                .padding(10)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))

                            Text("\(latestDoseEvent.status.description) at \(latestDoseEvent.timeLoggedDisplayString)")
                                .font(.headline)
                                .fontDesign(.rounded)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                } else {
                    Text("No Doses Logged for Today")
                        .font(.headline)
                        .padding(.leading)
                    Spacer()
                }

                Text("Symptoms")
                    .font(.title)
                    .fontDesign(.rounded)
                    .bold()
                    .padding(.horizontal)
                ScrollView {
                    if $medicationSideEffects.isEmpty {
                        Text("No Associated Symptoms")
                            .font(.headline)
                            .padding(.leading)
                    } else {
                        ForEach($medicationSideEffects, id: \.self) { sideEffect in
                            SymptomView(symptomModel: sideEffect)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                if healthSymptomDataAuthorized {
                    /// Provide RxNorm codes.
                    self.medicationSideEffects = SideEffects.symptoms(for: annotatedMedicationConcept)
                }
                // Modifying the trigger initiates the HealthKit data access request.
                triggerSymptomAuthorization.toggle()
            }
            .id(healthSymptomDataAuthorized)
            .navigationTitle(Text(annotatedMedicationConcept.name))
            .navigationBarTitleDisplayMode(.inline)
        }
        .healthDataAccessRequest(store: healthStore,
                                 shareTypes: symptomTypes,
                                 readTypes: symptomTypes,
                                 trigger: triggerSymptomAuthorization) { @Sendable result in
            Task { @MainActor in
                switch result {
                case .success:
                    healthSymptomDataAuthorized = true
                case .failure(let error):
                    print("Error when requesting HealthKit read-and-write authorizations: \(error)")
                }
            }
        }
    }
}
