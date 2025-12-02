/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view for rendering game content.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    private static let menuAttachmentID = "MenuAttachment"

    private let notificationTrigger = NotificationCenter.default.publisher(for: Notification.Name("RealityKit.NotificationTrigger"))
    
    @GestureState private var isDragActive = false
    
    var body: some View {
        RealityView { content, attachments in
            
            content.entities.removeAll()
            content.add(appModel.root)

            // Create a collision shape for the floor-input target.
            let floorColliderThickness: Float = 0.001
            let inputFloorShape = ShapeResource.generateBox(size: [GameSettings.volumeSize.width,
                                                                   floorColliderThickness,
                                                                   GameSettings.volumeSize.depth])
                .offsetBy(translation: [0, -GameSettings.volumeSize.height / 2 + floorColliderThickness / 2, 0])
            appModel.floorInputTarget.components.set(CollisionComponent(shapes: [inputFloorShape]))
            // Create a collision shape for the background-input target.
            let backgroundColliderThickness: Float = 0.1
            let inputBackgroundShape = ShapeResource.generateBox(size: [GameSettings.volumeSize.width,
                                                                        GameSettings.volumeSize.height,
                                                                        backgroundColliderThickness])
                .offsetBy(translation: [0, 0, -GameSettings.volumeSize.depth / 2 + backgroundColliderThickness / 2])
            appModel.backgroundInputTarget.components.set(CollisionComponent(shapes: [inputBackgroundShape]))

            // Add the menu attachment.
            if let menuAttachment = attachments.entity(for: Self.menuAttachmentID) {
                menuAttachment.position.y = -0.45
                menuAttachment.position.z = (GameSettings.volumeSize.depth / 2) - 0.3
                menuAttachment.scale = [0.7, 0.7, 0.7]
                appModel.root.addChild(menuAttachment)
            }
            
            if let tutorialPromptAttachment = attachments.entity(for: "TutorialPrompt") {
                tutorialPromptAttachment.position.y = (-GameSettings.volumeSize.height / 2) + 0.5
                appModel.tutorialPromptAttachmentRoot.addChild(tutorialPromptAttachment)
                appModel.root.addChild(appModel.tutorialPromptAttachmentRoot)
            }
        } update: { content, attachments in
            appModel.character.components[CharacterMovementComponent.self]?.canCollideWithLevelBoundary = !appModel.isDifficultyHard
            appModel.character.components[CharacterProgressComponent.self]?.isDifficultyHard = appModel.isDifficultyHard
            switch appModel.root.observable.components[GamePlayStateComponent.self] {
                case .introAnimation:
                    appModel.tutorialPromptAttachmentRoot.removeFromParent()
                case .starting, .playing(_):
                    if let rotationalCamera = appModel.root.first(withComponent: RotationalCameraFollowComponent.self)?.entity {
                        rotationalCamera.components[RotationalCameraFollowComponent.self]?.mode = .auto
                    }
                default:
                    break
            }
        } attachments: {
            Attachment(id: "TutorialPrompt") {
                TutorialPromptView(tutorialPromptAttachment: appModel.tutorialPromptAttachmentRoot)
            }
            
            Attachment(id: Self.menuAttachmentID) {
                MenuView()
            }
        }
        .onReceive(notificationTrigger, perform: { appModel.onReceiveNotification(notification: $0) })
        // Dual input gesture.
        .gesture(DualInputGesture(isDragActive: $isDragActive),
                 isEnabled: appModel.root.observable.components[GamePlayStateComponent.self]?.isPlayingGame == true &&
                            appModel.jumpInputMode == .pinch)
        // Single input gestures.
        .gesture(SingleInputJumpGesture(),
                 isEnabled: appModel.root.observable.components[GamePlayStateComponent.self]?.isPlayingGame == true &&
                            appModel.jumpInputMode == .look)
        .gesture(SingleInputFloorJumpGesture(),
                 isEnabled: appModel.root.observable.components[GamePlayStateComponent.self]?.isPlayingGame == true &&
                            appModel.jumpInputMode == .look)
        .gesture(SingleInputDragGesture(isDragActive: $isDragActive),
                 isEnabled: appModel.root.observable.components[GamePlayStateComponent.self]?.isPlayingGame == true &&
                            appModel.jumpInputMode == .look)
        .onChange(of: isDragActive) {
            if isDragActive == false {
                // Set the character's move direction and drag delta to zero.
                appModel.character.components[CharacterMovementComponent.self]?.inputMoveDirection = .zero
                appModel.character.components[CharacterMovementComponent.self]?.dragDelta = .zero
            }
            appModel.handInputVisualizer.components[InputVisualizerComponent.self]?.isDragActive = isDragActive
            appModel.handInputVisualizerInsidePortal.components[InputVisualizerComponent.self]?.isDragActive = isDragActive
            let useRelativeDragInput = appModel.rollInputMode == .relative
            appModel.handInputVisualizer.components[InputVisualizerComponent.self]?.useRelativeDragInput = useRelativeDragInput
            appModel.handInputVisualizerInsidePortal.components[InputVisualizerComponent.self]?.useRelativeDragInput = useRelativeDragInput
        }
        .ornament(attachmentAnchor: .scene(.bottomFront), ornament: { SettingsOrnamentView() })
        .onVolumeViewpointChange(updateStrategy: .all) { _, volumeViewpoint in
            // Update the character animation component with the current viewpoint.
            if let (characterAnimation, _) = appModel.root.first(withComponent: CharacterAnimationComponent.self) {
                characterAnimation.components[CharacterAnimationComponent.self]?.volumeViewpoint = volumeViewpoint
                // Blink briefly to hide the transition.
                characterAnimation.components[CharacterAnimationComponent.self]?.eyeAppearTimer = GameSettings.eyeBlinkDuration
            }
        }
        .onChange(of: appModel.root.observable.components[GamePlayStateComponent.self]) {
            guard let gamePlayState = appModel.root.components[GamePlayStateComponent.self],
                  let gameInfo = appModel.root.components[GameInfoComponent.self] else {
                return
            }
            switch gamePlayState {
            case .assetsLoaded:
                // Fade the portal in after the assets finish loading.
                Entity.animate(.easeInOut(duration: GameSettings.portalFadeInDuration)) {
                    appModel.portalEntity.components.set(OpacityComponent(opacity: 1.0))
                // Remove the opacity component from the portal when the fade in animation completes.
                } completion: {
                    appModel.portalEntity.components.remove(OpacityComponent.self)
                }
                    
                Task { @MainActor in
                    try await Task.sleep(for: .seconds(GameSettings.portalFadeInDuration / 2))
                    // Play the main level intro animation without starting the level if the player has already played through the tutorial.
                    if PersistentData().checkSkipIntro() {
                        appModel.playLevel(gameLevel: .main,
                                           introAnimationConfig: IntroAnimationConfigComponent(willPreserveCharacterWorldPosition: false,
                                                                                               willShowSpeechBubble: false,
                                                                                               willStartGameWhenComplete: false))
                        try await Task.sleep(for: .seconds(GameSettings.mainLevelIntroAnimationDuration - 1.5))
                    }
                    // Display the menu.
                    appModel.menuVisibility = .splashScreen
                }
            case .outroAnimation:
                guard gameInfo.currentLevel == .main,
                      let (_, characterProgress) = appModel.root.first(withComponent: CharacterProgressComponent.self) else { return }
                // Record the player's run.
                let persistentData = PersistentData()
                persistentData.recordRun(duration: characterProgress.runDurationTimer,
                                         rockFriendsCollected: characterProgress.collectedRockFriends,
                                         isDifficultyHard: characterProgress.isDifficultyHard)
                persistentData.save()
            default:
                break
            }
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(AppModel())
}
