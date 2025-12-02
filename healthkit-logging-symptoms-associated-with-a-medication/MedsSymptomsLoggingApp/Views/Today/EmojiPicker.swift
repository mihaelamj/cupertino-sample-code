/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Allows a person to select and save one emoji (of many) to represent how they feel after logging a dose of a medication.
*/

import HealthKit
import SwiftUI

struct EmojiPicker: View {
    let symptomModel: SymptomModel
    private var healthStore: HKHealthStore { HealthStore.shared.healthStore }

    @State private var selectedEmoji: SymptomIntensity?
    @Binding var isSymptomLogged: Bool

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Select Symptom Intensity")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .padding(12)
                HStack {
                    ForEach(SymptomIntensity.allCases, id: \.emoji) { emojiType in
                        Button {
                            selectedEmoji = emojiType
                        } label: {
                            EmojiButton(symptomIntensity: emojiType, isSelected: selectedEmoji == emojiType)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Symptom Intensity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: saveThenDismiss) {
                        Text("Save to HealthKit")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedEmoji == nil)
                }
            }
        }
    }

    private func saveThenDismiss() {
        isSymptomLogged = true
        if let selectedEmoji {
            Task {
                do {
                    try await saveSymptomSample(categoryTypeID: symptomModel.categoryID, emoji: selectedEmoji)
                } catch {
                    print("Unable to save your health data")
                }
                dismiss()
            }
        }
    }

    /// Performs the necessary steps to save a new symptom sample to HealthKit.
    private func saveSymptomSample(categoryTypeID: HKCategoryTypeIdentifier, emoji: SymptomIntensity) async throws {
        let categoryType = HKObjectType.categoryType(forIdentifier: categoryTypeID)!
        let symptomSample = HKCategorySample(type: categoryType,
                                             value: emoji.rawValue,
                                             start: Date(),
                                             end: Date())
        try await healthStore.save(symptomSample)
    }
}
