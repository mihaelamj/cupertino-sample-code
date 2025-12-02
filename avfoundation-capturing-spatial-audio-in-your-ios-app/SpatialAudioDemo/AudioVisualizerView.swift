/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that draws a real-time visualization of audio levels.
*/

import SwiftUI

/* This structure defines a view called AudioVisualizerView, which displays a real-time audio level visualizer
    similar to a volume meter or audio input bar.
    It draws a red vertical bar whose height represents the current microphone input level, updating dynamically as audio is recorded or monitored.
*/

struct AudioVisualizerView: View {
    @State var audioManager: AudioRecorder
    
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let levelHeight = CGFloat(audioManager.currentLevel) * height
            
            Rectangle()
                .fill(.red)
                .frame(width: geometry.size.width, height: levelHeight)
                .animation(.linear(duration: 0.1), value: levelHeight)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}
