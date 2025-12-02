/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that draws the archived medication tile and displays the most-recently logged dose date.
*/

import HealthKit
import SwiftUI

struct ArchivedMedicationView: View {
    var annotatedMedicationConcept: AnnotatedMedicationConcept
    var doseEventProvider: DoseEventProvider

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray)
                .cornerRadius(15.0)
                .padding(.horizontal)
                .frame(height: 100)
                .opacity(0.9)
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundStyle(.yellow)
                    .padding(10)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))

                VStack(alignment: .leading) {
                    Text(annotatedMedicationConcept.name)
                        .font(.headline)
                        .fontDesign(.rounded)

                    if let doseDateLogged = doseEventProvider.lastDoseLogged {
                        Text("Last logged dose: \(doseDateLogged.dateLoggedDisplayString)")
                            .font(.subheadline)
                            .fontDesign(.rounded)
                    }
                }

                Spacer()
            }
            .onAppear {
                Task {
                    try await doseEventProvider.fetchAndObserveMostRecentDoseAllTime()
                }
            }
            .padding()
        }
    }
}
