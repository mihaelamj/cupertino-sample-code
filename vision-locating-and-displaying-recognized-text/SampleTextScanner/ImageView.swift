/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays the captured image with bounding boxes, settings, and navigation buttons.
*/

import SwiftUI

struct ImageView: View {
    @Binding var showCamera: Bool
    @Binding var imageData: Data?

    @State private var imageOCR = OCR()
    @State private var languageCorrection = false
    @State private var selectedRecognitionLevel = "Accurate"
    @State private var selectedLanguage = Locale.Language(identifier: "en-US")

    var recognitionLevels = ["Accurate", "Fast"]

    /// Watch for changes to the request settings.
    var settingChanges: [String] {[
        languageCorrection.description,
        selectedRecognitionLevel,
        imageData!.description,
        selectedLanguage.maximalIdentifier
    ]}

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    NavigationLink(destination: InitialView()) {
                        Text("Retake Photo")
                            .padding()
                            .font(.headline)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .onTapGesture {
                                showCamera = true
                            }
                    }
                    Spacer()
                    NavigationLink(destination: TranscriptView(imageOCR: $imageOCR)) {
                        Text("View Text")
                            .padding()
                            .font(.headline)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }

                /// Convert the image data to a `UIImage`, and display it in an `Image` view.
                if let uiImage = UIImage(data: imageData!) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .overlay {
                            ForEach(imageOCR.observations, id: \.uuid) { observation in
                                Box(observation: observation)
                                    .stroke(.red, lineWidth: 1)
                            }
                        }
                        .padding()
                }

                /// Select the recognition level — fast or accurate.
                Picker("Recognition Level", selection: $selectedRecognitionLevel) {
                    ForEach(recognitionLevels, id: \.self) {
                        Text($0)
                    }
                }
                .overlay(Capsule().stroke(.blue, lineWidth: 1))

                /// Indicates whether the request uses the language-correction model.
                Toggle("Language Correction", isOn: $languageCorrection)
                    .frame(width: 250)

                /// Select which language the request prioritizes to detect.
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(imageOCR.request.supportedRecognitionLanguages, id: \.self) { language in
                        Text(language.maximalIdentifier)
                    }
                }
                .overlay(Capsule().stroke(.blue, lineWidth: 1))
            }
            /// Initially perform the request, and then perform the request when changes occur to the request settings.
            .onChange(of: settingChanges, initial: true) {
                updateRequestSettings()
                Task {
                    try await imageOCR.performOCR(imageData: imageData!)
                }
            }
        }
    }

    /// Update the request settings based on the selected options on the `ImageView`.
    func updateRequestSettings() {
        /// A Boolean value that indicates whether the system applies the language-correction model.
        imageOCR.request.usesLanguageCorrection = languageCorrection

        imageOCR.request.recognitionLanguages = [selectedLanguage]

        switch selectedRecognitionLevel {
        case "Fast":
            imageOCR.request.recognitionLevel = .fast
        default:
            imageOCR.request.recognitionLevel = .accurate
        }
    }
}
