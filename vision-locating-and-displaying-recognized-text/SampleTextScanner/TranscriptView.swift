/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays the captured image's text.
*/

import SwiftUI
import Vision

struct TranscriptView: View {
    @Binding var imageOCR: OCR

    var body: some View {
        VStack {
            NavigationStack {
                if imageOCR.observations.isEmpty {
                    Text("No text found")
                        .foregroundStyle(.gray)
                } else {
                    Text("Text extracted from the image:")
                        .font(.title2)

                    ScrollView {
                        /// Display the text from the captured image.
                        ForEach(imageOCR.observations, id: \.self) { observation in
                            Text(observation.topCandidates(1).first?.string ?? "No text recognized")
                                .textSelection(.enabled)
                        }
                        .foregroundStyle(.gray)
                    }
                }
            }
        }
    }
}
