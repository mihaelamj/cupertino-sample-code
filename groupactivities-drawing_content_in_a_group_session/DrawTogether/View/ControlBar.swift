/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that contains the buttons for interacting with the canvas or app.
*/

import SwiftUI
import GroupActivities
import PhotosUI

struct ControlBar: View {
    @ObservedObject var canvas: Canvas
    @StateObject var groupStateObserver = GroupStateObserver()
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        HStack {
            if canvas.groupSession == nil && groupStateObserver.isEligibleForGroupSession {
                Button {
                    canvas.startSharing()
                } label: {
                    Image(systemName: "person.2.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()

            if canvas.groupSession != nil {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()) {
                        Image(systemName: "photo.fill")
                            .foregroundColor(Color.white)
                            .background(Color.accentColor)
                }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            // Retrieve the selected asset in the form of Data
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                canvas.selectedImageData = data
                            }
                        }
                    }
            }

            Button {
                canvas.reset()
            } label: {
                Image(systemName: "trash.fill")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

struct ControlBar_Previews: PreviewProvider {
    static var previews: some View {
        ControlBar(canvas: Canvas())
            .previewLayout(.sizeThatFits)
    }
}
