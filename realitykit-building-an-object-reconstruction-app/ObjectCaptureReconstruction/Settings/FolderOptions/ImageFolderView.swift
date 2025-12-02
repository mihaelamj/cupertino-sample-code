/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Choose the image folder.
*/

import SwiftUI
import RealityKit
import os

private let logger = Logger(subsystem: ObjectCaptureReconstructionApp.subsystem,
                            category: "ImageFolderView")

struct ImageFolderView: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel
    @State private var selectedFolder: URL?
    @State private var imageURLs: [URL] = []
    @State private var numImages: Int?
    @State private var metadataAvailability = ImageHelper.MetadataAvailability()

    var body: some View {
        LabeledContent("Image Folder:") {
            VStack(spacing: 6) {
                HStack {
                    Text(title).foregroundStyle(.secondary).font(.caption)
                    
                    Spacer()
                    
                    if metadataAvailability.gravity && metadataAvailability.depth {
                        ImageMetadataView()
                    }

                    if selectedFolder != nil {
                        Button {
                            selectedFolder = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .frame(height: 15)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding([.leading, .trailing], 6)
                .padding(.top, 3)
                .frame(height: 20)
                
                Divider()
                    .padding(.top, -4)
                    .padding(.horizontal, 6)
                
                ImageFolderThumbnailView(imageURLs: $imageURLs)

                ImageFolderSelectionView(selectedFolder: $selectedFolder)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .onAppear {
                selectedFolder = appDataModel.imageFolder
            }
        }
        .frame(height: 110)
        .onChange(of: selectedFolder) {
            appDataModel.boundingBoxAvailable = false
            metadataAvailability = ImageHelper.MetadataAvailability()
            appDataModel.imageFolder = selectedFolder
        }
        .dropDestination(for: URL.self) { items, location in
            guard !items.isEmpty else { return false }
            var isDirectory: ObjCBool = false
            if let url = items.first,
               FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
               isDirectory.boolValue == true {
                selectedFolder = url
                return true
            }
            logger.info("Dragged item is not a folder!")
            return false
        }
        .task(id: selectedFolder) {
            guard let selectedFolder else {
                numImages = nil
                imageURLs = []
                metadataAvailability = ImageHelper.MetadataAvailability()
                appDataModel.boundingBoxAvailable = false
                return
            }

            imageURLs = ImageHelper.getListOfURLs(from: selectedFolder)
            if imageURLs.isEmpty {
                appDataModel.state = .error
                appDataModel.alertMessage = "\(String(describing: PhotogrammetrySession.Error.invalidImages(selectedFolder)))"
                self.selectedFolder = nil
                return
            }

            numImages = imageURLs.count

            // Check whether enough metadata is available.
            metadataAvailability = await ImageHelper.loadMetadataAvailability(from: imageURLs)
            appDataModel.boundingBoxAvailable = metadataAvailability.boundingBox
        }
    }

    private var title: String {
        if let numImages = numImages {
            return "\(numImages) Images"
        } else {
            return "Drag in a folder of Images"
        }
    }
}
