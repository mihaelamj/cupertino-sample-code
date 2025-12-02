/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the current recording time.
*/

import SwiftUI

/// A view that displays the current recording time.
struct RecordingTimeView: View {
    
    let time: TimeInterval
    
    var body: some View {
        Text(time.formatted)
            .padding([.leading, .trailing], 12)
            .padding([.top, .bottom], 0)
            .background(Color(white: 0.0, opacity: 0.5))
            .foregroundColor(.white)
            .font(.title2.weight(.semibold))
            .clipShape(.capsule)
    }
}

extension TimeInterval {
    var formatted: String {
        let time = Int(self)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        let formatString = "%0.2d:%0.2d:%0.2d"
        return String(format: formatString, hours, minutes, seconds)
    }
}

#Preview {
    RecordingTimeView(time: TimeInterval(floatLiteral: 500))
        .background(Image("video_mode"))
}
