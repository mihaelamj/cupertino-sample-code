/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides the initial option to select photos.
*/

import PhotosUI
import SwiftUI

struct MainView: View {
    @State var selectedPhotos = [PhotosPickerItem]()
    @State var selectedPhotosData = [Data]()
    @State var selfies = [Selfie]()
    
    @State var hasPerformedRequests = false
    
    var body: some View {
        NavigationStack {
            VStack {
                /// If the user hasn't selected images, display a default system image.
                if selectedPhotos.isEmpty || selfies.isEmpty {
                    Image(systemName: "photo.stack")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .foregroundStyle(.primary).opacity(0.3)
                    
                    if hasPerformedRequests {
                        Text("No faces detected. Try another photo!")
                            .foregroundStyle(.red)
                    }
                /// If the user has selected images, display them in a list.
                } else {
                    ScrollView {
                        Text("Tap an image to see more results")
                            .foregroundStyle(.gray)
                        
                        LazyVStack {
                            ForEach(selfies, id: \.self) { selfie in
                                if let image = UIImage(data: selfie.photo) {
                                    NavigationLink(destination: SelfieResultsView(selfie: selfie)) {
                                        ZStack(alignment: .bottom) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: 350)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(.gray)
                                                .frame(width: 50, height: 25)
                                                .opacity(0.70)
                                            
                                            Text("\(selfie.score, specifier: "%.2f")")
                                                .foregroundStyle(.white)
                                                .bold()
                                        }
                                        .padding()
                                    }
                                }
                            }
                        }
                    }
                }
                
                /// `PhotosPicker` to enable photo library selection.
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                    Text("Select Selfies")
                    Image(systemName: "photo.badge.plus")
                }
                .padding(10)
                .font(.headline)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .padding()
        }
        .onChange(of: selectedPhotos) {
            Task {
                /// Convert all `PhotosPickerItem` objects into data.
                for photo in selectedPhotos {
                    if let image = try? await photo.loadTransferable(type: Data.self) {
                        selectedPhotosData.append(image)
                    }
                }
                
                do {
                    /// Process all the selected photos concurrently, and store the `Selfie` objects in the `selfies` array.
                    selfies = try await processAllSelfies(photos: selectedPhotosData)
                    
                    hasPerformedRequests = true
                    
                    /// Reset the photo data array to allow for reselection.
                    selectedPhotosData.removeAll()
                } catch {
                    print("\(error.localizedDescription)")
                }
            }
        }
    }
}
