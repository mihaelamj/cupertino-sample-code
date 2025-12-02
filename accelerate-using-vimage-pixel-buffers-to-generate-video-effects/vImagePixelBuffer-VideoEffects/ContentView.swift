/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vImage Pixel Buffer Video Effects content view file.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var videoEffectsEngine: VideoEffectsEngine
    
    var body: some View {
        VStack {
            Picker("Choose effect", selection: $videoEffectsEngine.effect) {
                ForEach(VideoEffectsEngine.VideoEffects.allCases) { section in
                    Text(section.rawValue)
                        .tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            ImageView(videoEffectsEngine: videoEffectsEngine)
        }
        .padding()
    }
}

