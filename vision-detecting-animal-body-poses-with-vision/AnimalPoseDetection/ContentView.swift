/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's content view.
*/

import SwiftUI

struct ContentView: View {
    @StateObject var animalJoint = AnimalPoseDetector()
    @State var showEmoji: Bool = false
    var body: some View {
        VStack {
            Toggle("show the emoji view", isOn: $showEmoji).labelsHidden()
            if !showEmoji {
                    ZStack {
                        GeometryReader { geo in
                            AnimalSkeletonView(animalJoint: animalJoint, size: geo.size)
                        }
                    }.frame(maxWidth: .infinity)
                } else {
                    ZStack {
                        GeometryReader { geo in
                            AnimalEmojiView(animalJoint: animalJoint)
                        }
                    }.frame(maxWidth: .infinity)
                }
        }
    }
}
