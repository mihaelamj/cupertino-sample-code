/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct CollectionDetailEditingView: View {
    @Bindable var collection: Collection
    @Binding var isShowingLandmarksSelection: Bool
    @Binding var isShowingDeleteConfirmation: Bool
    
    var body: some View {
        VStack {
            VStack() {
                if collection.isFavoritesCollection {
                    HStack {
                        Text(collection.name)
                            .font(.largeTitle)
                        Spacer()
                    }
                    .padding()
                } else {
                    TextField("Name", text: $collection.name)
                        .padding()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .foregroundStyle(.white)
                
            )
            .padding([.top, .leading, .trailing, .bottom])
       
            if !collection.isFavoritesCollection {
                VStack() {
                    TextEditor(text: $collection.description)
                        .frame(height: Constants.textEditorHeight)
                        .padding()
                }
                .background(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .foregroundStyle(.white)
                    
                )
                .padding([.leading, .trailing, .bottom])
            }
            
            VStack {
                HStack {
                    Text("Select landmarks", comment: "Title above section letting users select landmarks to include in a collection.")
                        .padding()
                    Spacer()
                    Button {
                        isShowingLandmarksSelection.toggle()
                    } label: {
                        Image(systemName: "checklist")
                            .font(.title)
                            .foregroundStyle(.indigo)
                    }
                    .padding()
                }
                LandmarksGrid(landmarks: $collection.landmarks)
                    .padding([.leading, .trailing, .bottom])
            }
            .background(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .foregroundStyle(.white)
                
            )
            .padding([.leading, .trailing, .bottom])
        }
        .frame(minWidth: Constants.collectionFormMinWidth,
               idealWidth: Constants.collectionFormIdealWidth,
               maxWidth: Constants.collectionFormMaxWidth)
    }
}

#Preview {
    let modelData = ModelData()
    let previewCollection = modelData.userCollections.last!

    CollectionDetailEditingView(collection: previewCollection,
                                isShowingLandmarksSelection: .constant(false),
                                isShowingDeleteConfirmation: .constant(false))
}
