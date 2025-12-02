/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main interactive UI for subject-lifting effects.
*/

import SwiftUI
import PhotosUI

/// A preset picker for visual effects.
struct EffectPicker: View {

    @Binding var effect: Effect

    var body: some View {
        Picker("Effect", selection: $effect) {
            ForEach(Effect.allCases, id: \.self) { effect in
                Text(effect.rawValue)
                    .tag(effect)
            }
        }
    }
}

/// A preset picker for background images.
struct BackgroundPicker: View {

    @Binding var background: Background

    var body: some View {
        Picker("Background", selection: $background) {
            ForEach(Background.allCases, id: \.self) { background in
                Text(background.rawValue)
                    .tag(background)
            }
        }
    }
}

/// A view that presents an Open File dialog and enables a person to select an image from their Photos library.
struct ImagePicker: View {

    var pipeline: EffectsPipeline

    @State private var imageSelection: PhotosPickerItem? = nil

    var body: some View {
        PhotosPicker(selection: $imageSelection, matching: .images) {
            Label("Select Image", systemImage: "photo")
        }
            .onChange(of: imageSelection) { _, newSelection in
                self.loadInputImage(fromPhotosPickerItem: newSelection)
            }
    }

    private func loadInputImage(fromPhotosPickerItem item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .failure(let error):
                print("Failed to load: \(error)")
                return

            case .success(let maybeData):
                guard let data = maybeData else {
                    print("Failed to load image data.")
                    return
                }
                guard let image = CIImage(data: data) else {
                    print("Failed to create image from selected photo.")
                    return
                }
                DispatchQueue.main.async {
                    pipeline.inputImage = image
                }
            }
        }
    }
}

/// A view that displays the final postprocessed output.
struct OutputView: View {

    @Binding var output: UIImage

    var body: some View {
        Image(uiImage: output)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A view that displays underneath the output image.
///
/// This view displays under the subject when a transparent background is present.
struct SubImageContent: View {

    var body: some View {
        Text("WWDC23")
            .font(.system(size: 80, design: .rounded))
            .offset(y: -60)
            .foregroundStyle(
                .linearGradient(
                    colors: [.purple, .blue],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

/// A primary content view for the app.
struct ContentView: View {

    @EnvironmentObject var pipeline: EffectsPipeline
    @State private var outputViewSize = CGSize.zero

    var body: some View {
        VStack {
            ZStack {
                SubImageContent()
                GeometryReader { geometry in
                    OutputView(output: $pipeline.output)
                        .onAppear {
                            outputViewSize = geometry.size
                        }
                        .onTapGesture { location in
                            // Normalize the tap position.
                            pipeline.subjectPosition = CGPoint(
                                x: location.x / outputViewSize.width,
                                y: location.y / outputViewSize.height)
                        }
                }
            }
            Form {
                EffectPicker(effect: $pipeline.effect)
                BackgroundPicker(background: $pipeline.background)
                ImagePicker(pipeline: pipeline)
            }
                .frame(height: 200)
        }
    }
}
