/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that draws the medication tile and adds navigation to open `DoseEventView`.
*/

import HealthKit
import SwiftUI

struct MedicationView: View {

    @Environment(MedicationProvider.self) private var medicationProvider
    var annotatedMedicationConcept: AnnotatedMedicationConcept
    var doseEventProvider: DoseEventProvider

    @State private var isConceptTapped = false

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .fill(Color.green)
                    .cornerRadius(15.0)
                    .padding(.horizontal)
                    .frame(height: 100)
                    .opacity(0.9)
                HStack {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(.yellow)
                        .padding(10)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))

                    Text(annotatedMedicationConcept.name)
                        .font(.headline)
                        .fontDesign(.rounded)

                    Spacer()

                    NavigationLink {
                        DoseEventView(annotatedMedicationConcept: annotatedMedicationConcept,
                                      doseEventProvider: doseEventProvider)
                        .environment(medicationProvider)
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                            .padding(30)
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isConceptTapped {
                            isConceptTapped = true
                        }
                    }
                    .onEnded { _ in
                        isConceptTapped = false
                    }
            )
        }
    }
}
