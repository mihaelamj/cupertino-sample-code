/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that contains all RealityKit content for the game.
*/

import SwiftUI
import RealityKit
import PyroPanda
import WorldCamera
import CharacterMovement
import ControllerInput
import ThumbStickView
import Metal

struct PyroPandaView: View {
    @Environment(AppModel.self) internal var appModel

    var hero: Entity? {
        appModel.gameRoot?.findEntity(named: "max_parent")
    }

    @State var showControls: Bool = false

    var body: some View {
        ZStack {
            #if !os(visionOS)
            Color.black
            #endif
            if supportsFullGame {
                RealityView { content in
                    #if os(iOS) || os(macOS)
                    if BloomEffect.deviceSupportsEffect() {
                        content.renderingEffects.customPostProcessing = .effect(BloomEffect())
                    }
                    #endif
                    guard let game = try? await Entity(
                        named: "Scene", in: pyroPandaBundle
                    ) else { return }

                    appModel.gameRoot = game

                    #if os(tvOS)
                    adjustRenderingQuality(&content, game)
                    #endif

                    await setupGameParts(game, content)
                    content.add(game)
                    showControls = true
                } placeholder: {
                    loadingPlaceholder()
                }
                .ignoresSafeArea()

                #if os(iOS)
                if showControls {
                    self.platformerThumbControls
                }
                #endif
            } else {
                gameNotSupportedUI()
            }
        }
        #if os(macOS)
        .onKeyPress(phases: .all, action: onKeypress(_:))
        #endif
        #if !os(tvOS)
        .allowedDynamicRange(.high)
        #endif
    }

    fileprivate func setupGameParts(_ game: Entity, _ content: some RealityViewContentProtocol) async {

        if let hero {
            self.setupWorldCamera(target: hero)
            await self.heroSetup(hero)
        }

        await setupEnvironmentCollisions(on: game, content: content)
        try? await setupEnemies(content: content)

        if let platform1 = game.findEntity(named: "mobile_platform_1"),
           let platform2 = game.findEntity(named: "mobile_platform_2") {
            animatePlatforms(platform1, platform2)
        }

        if let coin = game.findEntity(named: "coin"),
           let key = game.findEntity(named: "key") {
            self.setupCollectables(coin: coin, key: key, content: content)
        }

        self.setupAudio(root: game, content: content)

        setupCaptiveFriends(game)
    }

#if os(iOS)
    @State var movementThumbstick: CGPoint = .zero
    @State var cameraAngleThumbstick: CGPoint = .zero

    /// The thumbstick UI to move the character and the camera.
    var platformerThumbControls: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom, content: {
                ThumbStickView(updatingValue: $movementThumbstick)
                    .onChange(of: movementThumbstick) { _, newValue in
                        let movementVector: SIMD3<Float> = [Float(newValue.x), 0, Float(newValue.y)] / 10
                        hero?.components[CharacterMovementComponent.self]?.controllerDirection = movementVector
                    }
                Spacer()
                ZStack(alignment: .topLeading) {
                    ThumbStickView(updatingValue: $cameraAngleThumbstick)
                        .onChange(of: cameraAngleThumbstick) { _, newValue in
                            let movementVector: SIMD2<Float> = [Float(newValue.x), Float(-newValue.y)] / 30
                            appModel.gameRoot?.findEntity(named: "camera")?.components[WorldCameraComponent.self]?
                                .updateWith(continuousMotion: movementVector)

                        }
                    HStack(spacing: 16) {
                        // Jump button.
                        Image(systemName: "arrow.up")
                            .frame(width: 50, height: 50)
                            .font(.system(size: 36))
                            .glassEffect(.regular.interactive())
                            .onLongPressGesture(minimumDuration: 0.0, perform: {}, onPressingChanged: { isPressed in
                                hero?.components[CharacterMovementComponent.self]?.jumpPressed = isPressed
                            })
                            .padding(.leading, -40)

                        // Attack/Spin button.
                        Image(systemName: "tornado")
                            .frame(width: 50, height: 50)
                            .font(.system(size: 36))
                            .glassEffect(.regular.interactive())
                            .onLongPressGesture(minimumDuration: 0.0, perform: {}, onPressingChanged: { isPressed in
                                if isPressed, let attackAnim = try? HeroAttackAction.animation(duration: 1) {
                                    hero?.playAnimation(attackAnim)
                                }
                            })
                            .padding(.top, -68)
                            .padding(.leading, -20)
                    }
                }
            }).padding()
        }
    }
#endif
}

extension CharacterMovementComponent {
    static var dependencies: [SystemDependency] {
        [.after(ControllerInputSystem.self)]
    }
}

#Preview {
    PyroPandaView()
        .environment(AppModel())
}
