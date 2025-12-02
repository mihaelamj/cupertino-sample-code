/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that manages the image navigation and importing/exporting behavior.
*/

import Foundation
import SwiftUI
import PhotosUI

// The Asset and EditedAsset types track the current image,
// and manage edits without overwriting the original.
struct MainView: View {

    var renderer = Renderer()

    @State var selectedItems: [PhotosPickerItem] = []
    @State var assets: [Asset] = []
    @State var selectedAsset: Asset?
    @State var editedAsset: EditedAsset?

    @State var isEditing: Bool = false
    @State var isImporting: Bool = false
    @State var isExporting: Bool = false
    @State var isShowingPhotoPicker: Bool = false

    var body: some View {

        NavigationStack {
            // Use the geometry reader to keep the film strip and edit controls
            // at an appropriate size.
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    if isEditing {
                        RenderView(asset: editedAsset!)
                    } else {
                        ImageView(asset: selectedAsset)
                            .aspectRatio(contentMode: .fit)
                    }

                    Spacer(minLength: 0)
                    Divider()

                    if isEditing {
                        AdjustView(asset: editedAsset!)
                            .frame(height: geometry.size.height / 10.0)
                            .padding(.top, 10)
                    } else {
                        // Use the constrainedHigh option to avoid HDR/SDR coexistence issues.
                        FilmStrip(assets: $assets, selectedAsset: $selectedAsset)
                            .allowedDynamicRange(.constrainedHigh)
                            .frame(height: geometry.size.height / 10.0)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    if !isEditing {
                        Button {
                            importFromPhotoLibrary()
                        } label: {
                            Image(systemName: "photo.badge.plus")
                        }
                        Button {
                            isImporting = true
                        } label: {
                            Image(systemName: "doc.badge.plus")
                        }
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if isEditing {
                        Button {
                            isEditing = false
                        } label: {
                            Text("Cancel")
                        }
                        .disabled(selectedAsset == nil)
                        Button {
                            saveEdit()
                        } label: {
                            Text("Save")
                        }
                        .disabled(selectedAsset == nil)
                    } else {
                        Button {
                            toggleEdit()
                        } label: {
                            Text("Edit")
                        }
                        .disabled(selectedAsset == nil)
                    }
                }
            }
        }
        // Load images from the Photos library.
        .photosPicker(isPresented: $isShowingPhotoPicker,
                      selection: $selectedItems,
                      matching: .images,
                      preferredItemEncoding: .current,
                      photoLibrary: PHPhotoLibrary.shared())
        // Load images from the file system.
        .fileImporter(isPresented: $isImporting,
                      allowedContentTypes: [.image],
                      allowsMultipleSelection: true) { result in
            if let urls = try? result.get(), !urls.isEmpty {
                // Asynchronously load images to avoid blocking the main thread.
                Task.detached {
                    let assets = loadImages(from: urls)
                    self.didLoad(assets)
                }
            }
        }
        // Save the edited image to an appropriate location.
        .fileExporter(isPresented: $isExporting,
                      document: editedAsset,
                      contentTypes: [.heic, .png],
                      defaultFilename: editedAsset?.defaultFilename) { result in
            do {
                let fileURL = try result.get()
                reload(from: fileURL)
            } catch {
                print("Failed to export: \(error)")
            }
            self.isEditing = false
        }
        // After loading items from the Photos library, convert them into
        // assets.
        .onChange(of: selectedItems) {
            Task.detached { [selectedItems] in
                let assets = await loadPhotos(from: selectedItems)
                self.didLoad(assets)
            }
        }
        .onChange(of: selectedAsset) {
            if selectedAsset == nil {
                isEditing = false
                editedAsset = nil
            }
        }
    }

    func importFromPhotoLibrary() {

        // Check the authorization status for the Photos library. Write access is needed
        // to save edited images back to Photos.
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        // If it's possible to read images, allow images to load.
        if status == .authorized || status == .limited {
            isShowingPhotoPicker = true
        } else if status == .notDetermined {
            // If the user hasn't given you access to their Photos library, request it.
            Task {
                let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                if status == .authorized || status == .limited {
                    isShowingPhotoPicker = true
                }
            }
        }

    }

    @MainActor
    func toggleEdit() {

        guard let asset = selectedAsset else { return }

        if let photoAsset = asset.photoAsset {
            // This asset is coming from the Photos library.
            let options = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = { adjustmentData in
                return adjustmentData.formatIdentifier == Adjustment.formatIdentifier &&
                       adjustmentData.formatVersion == Adjustment.formatVersion
            }
            photoAsset.requestContentEditingInput(with: options) { input, info in
                if let editingInput = input {
                    self.editedAsset = EditedAsset(asset: asset, renderer: renderer, input: editingInput)
                    self.isEditing = true
                } else {
                    print("failed to start editing: \(info)")
                    self.editedAsset = nil
                    self.isEditing = false
                }
            }
        } else {
            // This asset is coming from a file on the file system.
            self.editedAsset = EditedAsset(asset: asset, renderer: renderer)
            self.isEditing = true
        }

    }

    @MainActor
    func saveEdit() {

        if let photoAsset = editedAsset?.asset.photoAsset,
           let editingOutput = editedAsset?.editingOutput,
           let data = try? Data(contentsOf: editingOutput.renderedContentURL) {

            // This is a Photos asset, so save it back to the Photos library.
            do {
                try PHPhotoLibrary.shared().performChangesAndWait {
                    let change = PHAssetChangeRequest(for: photoAsset)
                    change.contentEditingOutput = editingOutput
                }
                print("Success saving changes to the Photos library.")
                // Reload the edited asset so that the updated version appears in the
                // film strip.
                reload(from: data, identifier: photoAsset.localIdentifier)
            } catch {
                print("Failed to save changes to the Photos library: \(error)")
            }

            self.isEditing = false

        } else {
            // This is a file from the file system, so save it using the fileExporter.
            self.isExporting = true
        }

    }

    nonisolated
    func loadImages(from fileURLs: [URL]) -> [Asset] {
        let assets: [Asset] = fileURLs.map { url in
            return Asset.load(from: url)
        }
        return assets
    }

    nonisolated
    func loadPhotos(from items: [PhotosPickerItem]) async -> [Asset] {
        var assets: [Asset] = []
        for item in items {
            do {
                // Get the local identifier to find the corresponding photo asset in the Photos library.
                if let localIdentifier = item.itemIdentifier,
                   let data = try await item.loadTransferable(type: Data.self) {
                    let asset = Asset.load(from: data, identifier: localIdentifier)
                    assets.append(asset)
                }
            } catch {
                print("Failed to load data.")
            }
        }
        return assets
    }

    func didLoad(_ assets: [Asset]) {
        self.assets.append(contentsOf: assets)
        self.selectedAsset = assets.first
    }

    func reload(from file: URL) {
        reload(Asset.load(from: file))
    }

    func reload(from data: Data, identifier: String) {
        reload(Asset.load(from: data, identifier: identifier))
    }

    func reload(_ asset: Asset?) {
        guard let oldAsset = selectedAsset,
              let newAsset = asset,
              let idx = assets.firstIndex(of: oldAsset)
        else {
            return
        }
        self.assets[idx] = newAsset
        self.selectedAsset = newAsset
    }
}
