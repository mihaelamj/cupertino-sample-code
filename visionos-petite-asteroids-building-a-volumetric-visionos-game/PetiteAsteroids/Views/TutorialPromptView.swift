/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view showing prompts to the player during the tutorial.
*/

import RealityKit
import SwiftUI

struct TutorialPromptView: View {
    @Environment(AppModel.self) private var appModel
    let tutorialPromptAttachment: Entity

    var body: some View {
        if let tutorialPromptData = tutorialPromptAttachment.observable.components[TutorialPromptDataComponent.self] {
            VStack(alignment: .center) {

                VStack(alignment: .center) {
                    Text(tutorialPromptData.title ?? "")
                        .font(.largeTitle)
                        .padding(.bottom, 10)
                    Text(tutorialPromptData.message?[appModel.jumpInputMode] ?? "")
                        .font(.system(size: 22))
                }
                .padding()

                if let tutorialPromptButtonLabel = tutorialPromptData.buttonLabel {
                    Button {
                        tutorialPromptAttachment.removeFromParent()
                        // An optional notification to post when the player taps the button.
                        if let tutorialPromptButtonNotification = tutorialPromptData.buttonNotification, let scene = appModel.root.scene {
                            scene.postRealityKitNotification(notification: tutorialPromptButtonNotification)
                        }
                    } label: {
                        Text(tutorialPromptButtonLabel)
                            .font(.title)
                    }
                    .buttonStyle(AttachmentButton())
                    .frame(maxWidth: 300)
                    .padding(.top, 10)
                }
            }
            .attachment()
            .glassBackgroundEffect()
            .id(tutorialPromptData.title)
            .transition(.opacity.animation(.easeInOut(duration: 0.25).delay(0.25)))
        }
    }
}
