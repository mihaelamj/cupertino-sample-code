/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents possible medications to toggle on and off.
*/

import SwiftUI

extension MedicationChartsView {

    struct MedicationSelectorView: View {
        var concepts: [AnnotatedMedicationConcept]
        @Binding private var selectedMedication: AnnotatedMedicationConcept?

        init(concepts: [AnnotatedMedicationConcept], selectedMedication: Binding<AnnotatedMedicationConcept?>) {
            self.concepts = concepts
            self._selectedMedication = selectedMedication
        }

        var body: some View {
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(concepts, id: \.self) { concept in
                        HStack {
                            Button(action: {
                                selectedMedication = concept
                            }, label: {
                                if selectedMedication == concept {
                                    Text(Image(systemName: "checkmark.circle.fill")) // Size the SF Symbols to the text.
                                        .foregroundStyle(Color.blue)
                                    Text(concept.name).bold()
                                        .foregroundStyle(Color.primary)
                                } else {
                                    Text(Image(systemName: "checkmark.circle"))
                                        .foregroundStyle(Color.blue)
                                    Text(concept.name)
                                        .foregroundStyle(Color.primary)
                                }
                            })
                        }
                        .padding(8)
                        .background(Color(uiColor: .systemFill))
                        .clipShape(Capsule())
                    }
                }
                .padding()
            }.scrollClipDisabled()
        }
    }

}
