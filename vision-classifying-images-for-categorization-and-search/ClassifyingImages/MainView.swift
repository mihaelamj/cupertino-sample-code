/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Analyzes and labels images using a Vision classification request.
*/

import SwiftUI
import Vision

struct MainView: View {
    @State private var imageURLS: [URL] = []
    @State private var images: [ImageFile] = []
    @State private var searchTerm = ""
    @State private var showFilePicker = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if !imageURLS.isEmpty {
                    Text("Click an image to view it's classification results")
                        .font(.title2)
                        .padding(.top)
                        .task {
                            do {
                                images = try await classifyAllImages(urls: imageURLS)
                            } catch {
                                print("Error")
                            }
                        }
                    
                    if images.count != images.count {
                        ProgressView()
                            .progressViewStyle(.linear)
                            .frame(width: 300)
                    } else {
                        // Tapping one of the images navigates the app to the `ResultsView`.
                        List {
                            // Present either all the images, or those that contain classification labels equal to the search term.
                            ForEach(searchResults, id: \.url) { item in
                                NavigationLink(destination: ResultsView(image: item)) {
                                    AsyncImage(url: item.url) { image in
                                        image.resizable()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 128, height: 128)
                                    .clipShape(.rect(cornerRadius: 5))
                                    .padding(10)
                                    
                                    Text("\(item.name)")
                                        .padding(20)
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .searchable(text: $searchTerm)
                    }
                }
            }
        }
        .navigationTitle("ClassifyingImages")
        .onAppear(perform: selectImages)
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.jpeg, .png, .heic], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let files):
                files.forEach { file in
                    let access = file.startAccessingSecurityScopedResource()
                    if !access { return }
                    imageURLS.append(file)
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    var searchResults: [ImageFile] {
        if searchTerm.isEmpty {
            // If the search bar is empty, keep all of the images available.
            return images
        } else {
            // The only images that are available are those that contain classification labels equal to the search term.
            return images.filter({ $0.observations.keys.contains(searchTerm) })
        }
    }
    
    func selectImages() {
        showFilePicker.toggle()
    }
}
