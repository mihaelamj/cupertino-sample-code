/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top-level view of the app.
*/

import SwiftUI
import PhotosUI

struct ContentView: View {

    @State private var selectedPickerItem: PhotosPickerItem?
    @State private var selectedAsset: CinematicAsset?

    @State private var continuation: AsyncStream<String>.Continuation?

    var body: some View {

        VStack {

            photosPicker
                .disabled(selectedAsset != nil)

            if let $selectedAsset = Binding($selectedAsset) {
                AssetView(asset: $selectedAsset)
            } else {
                Rectangle()
                    .foregroundColor(.clear)
                    .overlay {
                        Text("No selected asset").font(.largeTitle).opacity(0.5)
                    }
            }
        }

        .onChange(of: selectedPickerItem) { _, newValue in
            // Return early if there is no new item.
            guard let newValue else { return }

            // Return early if there is no item identifier on the new item or same asset.
            guard let localIdentifier = newValue.itemIdentifier else { return }
            if let asset = selectedAsset {
                if asset.localIdentifier == localIdentifier {
                    return
                }
            }

            // Yield the identifier to the identifier stream.
            continuation?.yield(localIdentifier)
        }

        // This task waits on a stream of local identifiers.
        .task {

            let identifierStream = AsyncStream<String> { continuation in
                self.continuation = continuation
            }

            for await localIdentifier in identifierStream {

                // Continue to the next identifier if this one creates a `nil` asset.
                guard let asset = await CinematicAsset(localIdentifier: localIdentifier) else { continue }

                // Set the `selectedAsset`.
                selectedAsset = asset
            }
        }
    }

    private var photosPicker: some View {
        HStack {
            Spacer()
            PhotosPicker(selection: $selectedPickerItem,
                         matching: .cinematicVideos,
                         photoLibrary: .shared()) {
                Label("Choose Asset", systemImage: "video")
            }
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
