/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that displays the video-processing results, including thumbnails with text and a button that resets to the home screen.
*/

import SwiftUI
import AVFoundation

struct ResultView: View {
    /// The array that the view takes to store the top-rated thumbnails based on aesthetics scores.
    var topThumbnails: [Thumbnail]

    /// The function that the view takes to reset the video file and the thumbnails.
    var tryAgain: () -> Void

    /// The spacing value for the vertical stack.
    let spacing: CGFloat = 20

    var body: some View {
        VStack(spacing: spacing) {
            Text("Best Rated Thumbnails")
                .font(.title)

            HStack {
                // Loop through all thumbnails and display the image, time, and score.
                ForEach(topThumbnails) { thumbnail in
                    VStack {
                        Image(thumbnail.image, scale: 1.0, label: Text("Image"))
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300)
                            .shadow(radius: 12)
                            .padding()
                        
                        let formattedTime = String(format: "%.2f", thumbnail.frame.time.seconds)
                        let formattedScore = String(format: "%.f", thumbnail.frame.score * 100)
                        Text("Captured at \(formattedTime) seconds with a score of \(formattedScore).")
                    }
                }
            }

            if topThumbnails.count < 3 {
                Text("Try videos with more scene changes to see more results.")
                    .bold()
                    .foregroundStyle(.red)
            }

            Button(action: tryAgain) {
                Text("Reset")
                    .font(.title2)
                    .padding(5)
            }
        }
        .padding()
    }
}
