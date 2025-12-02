/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI

struct MainView: View {
    /// The video file to process each frame.
    @State private var videoFile: VideoFile? = nil

    /// The array that stores the top-rated thumbnails.
    @State private var thumbnails: [Thumbnail] = []

    /// The Boolean value that tracks whether to show the file importer.
    @State private var showFileImporter: Bool = false

    /// The progression of the video that processes.
    @State private var progress: Float = 0

    /// The spacing value for the vertical stack.
    let spacing: CGFloat = 20

    var body: some View {
        NavigationStack {
            VStack(spacing: spacing) {
                // Display a text and a button if there is no video file.
                if videoFile == nil {
                    Text("Select a video to generate the best thumbnails")
                        .font(.title)
                        .multilineTextAlignment(.center)

                    /// The button that opens the file importer.
                    Button(action: selectFile) {
                        Text("Select Video File")
                            .font(.title2)
                            .padding(5)
                    }
                } else {
                    // Display the load animation if `thumbnails` is empty.
                    if thumbnails.isEmpty {
                        Text("Processing...")
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .frame(width: 300)
                            .task {
                                if let url = videoFile?.url {
                                    // Process the video with the url of the video.
                                    thumbnails = await processVideo(for: url, progression: $progress)
                                }
                            }
                    } else {
                        // Navigate to the results when the video fully processes.
                        ResultView(topThumbnails: thumbnails, tryAgain: reset)
                    }
                }
            }
        }
        .navigationTitle("Generate Video Thumbnails")
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.quickTimeMovie, .mpeg4Movie], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let file):
                if let url = file.first {
                    // Gain access to the directory.
                    let accessGranted = url.startAccessingSecurityScopedResource()
                    if accessGranted {
                        // Create and assign the video file with the url.
                        videoFile = VideoFile(url: url)
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    /// Toggle `showFileImporter` to allow the file importer to present.
    func selectFile() {
        showFileImporter.toggle()
    }
    
    /// Reset the video file and the thumbnails.
    func reset() {
        videoFile = nil
        thumbnails.removeAll()
        progress = 0
    }
}

#Preview {
    MainView()
}
