/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's emoji view, which overlays emojis on the joint landmarks.
*/

import SwiftUI

struct AnimalEmojiView: View {
    // Get the animal joint locations.
    @StateObject var animalJoint = AnimalPoseDetector()
    var body: some View {
        if animalJoint.animalBodyParts.isEmpty == false {
            VStack {
                ZStack {
                    GeometryReader { geo in
                        let width = UIScreen.main.bounds.size.width
                        let height = UIScreen.main.bounds.size.height
                        DisplayView(animalJoint: animalJoint)
                        // skates emoji
                        .overlay {
                            if let leftFrontPaw = animalJoint.animalBodyParts[.leftFrontPaw] {
                                VStack(spacing: 0) {
                                    Text("🛼")
                                        .font(.system(size: 100, weight: .heavy))
                                        .position(x: leftFrontPaw.location.x * width - 10, y: (1 - leftFrontPaw.location.y) * height - 30)
                                        .colorInvert()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .overlay {
                            if let leftBackPaw = animalJoint.animalBodyParts[.leftBackPaw] {
                                VStack(spacing: 0) {
                                    Text("🛼")
                                        .font(.system(size: 100, weight: .heavy))
                                        .position(x: leftBackPaw.location.x * width - 10, y: (1 - leftBackPaw.location.y) * height - 30)
                                        .colorInvert()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        // helmet emoji
                        .overlay {
                            if let leftEar = animalJoint.animalBodyParts[.leftEarTop] {
                                VStack(spacing: 0) {
                                    Text("⛑️")
                                        .font(.system(size: 180, weight: .heavy))
                                        .position(x: leftEar.location.x * width - 10, y: (1 - leftEar.location.y) * height - 30)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        // glasses emoji
                        .overlay {
                            if let leftEye = animalJoint.animalBodyParts[.leftEye] {
                                VStack(spacing: 0) {
                                    Text("🥽")
                                        .font(.system(size: 180, weight: .heavy))
                                        .position(x: leftEye.location.x * width, y: (1 - leftEye.location.y) * height - 20)
                                        .colorInvert()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
