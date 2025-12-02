/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that draws the custom media timeline of flashing lights below the video.
*/

import SwiftUI

struct FlashingTimelineView: View {
    
    // Video metadata.
    private var videoFlashingTimes: [[Double]]
    private var videoLength: CGFloat = 23.0 // In seconds.
    
    private var width: CGFloat
    
    init(_ timelineWidth: CGFloat) {
        width = timelineWidth
        
        // Start and end times (in seconds) in the sample video `Resources/video.mp4`
        // that contain segments of bright, flashing light effects.
        // The values in this example are entered manually,
        // but your app might determine these time ranges by analyzing your
        // videos to calculate which frames contain a high risk of flashing effects,
        // or obtain them from video metadata.
        videoFlashingTimes = [
            // First sequence of flashing lights.
            [7.5 / videoLength, 11.0 / videoLength],
            
            // Second sequence of flashing lights.
            [11.5 / videoLength, 15.0 / videoLength],
            
            // Third sequence of flashing lights.
            [15.5 / videoLength, 18.5 / videoLength],
            
            // Fourth sequence of flashing lights.
            [19.0 / videoLength, 23.0 / videoLength]
        ]
    }
    
    /// - Tag: FlashingTimelineView
    var body: some View {
        ForEach(videoFlashingTimes, id: \.self) { timeRange in
            // Draws red rectangles to indicate which segments of the video
            // contain flashing light effects. The position relies on the
            // start and end times of each segment in `videoFlashingTimes`.
            RoundedRectangle(cornerRadius: 2)
                .fill(.red)
                .position(x: (timeRange[0] * width) + ((timeRange[1] * width) - (timeRange[0] * width)) / 2)
                .frame(width: (timeRange[1] * width) - (timeRange[0] * width), height: 10)
        }
    }
}
