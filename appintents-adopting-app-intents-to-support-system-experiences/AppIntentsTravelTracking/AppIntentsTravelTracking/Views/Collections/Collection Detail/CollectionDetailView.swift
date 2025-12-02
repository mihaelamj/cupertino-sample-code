/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct CollectionDetailView: View {
    @Environment(ModelData.self) var modelData
    @Environment(\.dismiss) var dismiss

    @Bindable var collection: Collection
    @State var isEditing: Bool = false
    @State var isShowingLandmarksSelection: Bool = false
    @State var isShowingDeleteConfirmation: Bool = false
    
    var body: some View {
        ScrollView(.vertical) {
            HStack {
                if isEditing {
                    CollectionDetailEditingView(collection: collection,
                                                isShowingLandmarksSelection: $isShowingLandmarksSelection,
                                                isShowingDeleteConfirmation: $isShowingDeleteConfirmation)
                } else {
                    CollectionDetailDisplayView(collection: collection)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        #if os(iOS)
        .background(Color(uiColor: .systemGray6))
        #endif
        #if os(macOS)
        .background(Color(nsColor: .secondarySystemFill))
        #endif
        .navigationBarBackButtonHidden(isEditing)
        .sheet(isPresented: $isShowingLandmarksSelection) {
            LandmarksSelectionList(landmarks: $collection.landmarks)
                .frame(minWidth: 200.0, minHeight: 400.0)
        }
        .toolbar {
            #if os(macOS)
            let deleteButtonPlacement: ToolbarItemPlacement = .destructiveAction
            let editButtonPlacement: ToolbarItemPlacement = .primaryAction
            #elseif os(iOS)
            let deleteButtonPlacement: ToolbarItemPlacement = .topBarLeading
            let editButtonPlacement: ToolbarItemPlacement = .topBarTrailing
            #endif
            if isEditing && !collection.isFavoritesCollection {
                ToolbarItem(placement: deleteButtonPlacement) {
                    deleteCollectionToolbarItemButton
                }
            }
            ToolbarItem(placement: editButtonPlacement) {
                Button() {
                    withAnimation {
                        isEditing.toggle()
                    }
                } label: {
                    let imageName: String = isEditing ? "checkmark" : "pencil"
                    Image(systemName: imageName)
                }
            }
        }
    }
        
    var deleteCollectionToolbarItemButton: some View {
        Button(role: .destructive) {
            isShowingDeleteConfirmation = true
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(.red)
        }
        .confirmationDialog("Delete?",
                            isPresented: $isShowingDeleteConfirmation,
                            presenting: collection) { collection in
            Button(role: .destructive) {
                // Remove collection from model data
                modelData.remove(collection)
                
                isEditing = false
                dismiss()
            } label: {
                Text("Delete", comment: "Delete button shown in an alert asking for confirmation to delete the collection.")
            }
            Button("Keep") {
                isShowingDeleteConfirmation = false
            }
        } message: { details in
            Text("Select Delete to permanently remove ‘\(collection.name)’.",
                 comment: "Message in an alert asking the user whether they want to delete a collection with a given name.")
        }
    }
}

#Preview {
    let modelData = ModelData()
    let previewCollection = modelData.userCollections.last!

    NavigationStack {
        CollectionDetailView(collection: previewCollection)
            .environment(modelData)
    }
}

