/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for Petite Asteroids.
*/

import SwiftUI
import RealityKit
import RealityKitContent

@main
struct PetiteAsteroids: App {

    @State private var appModel = AppModel()
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.physicalMetrics) var physicalMetrics

    private func registerSystems() {
        GamePlayIntroAnimationSystem.registerSystem()
        CharacterSpawnPointSystem.registerSystem()
        CharacterMovementSystem.registerSystem()
        CharacterAnimationSystem.registerSystem()
        PausePhysicsSystem.registerSystem()
        RockCollectorSystem.registerSystem()
        CompoundCollisionMarkerSystem.registerSystem()
        InputVisualizerSystem.registerSystem()
        RotationalCameraFollowSystem.registerSystem()
        CheckpointSystem.registerSystem()
        WinGameTriggerSystem.registerSystem()
        AudioEventSystem.registerSystem()
        AudioCueSystem.registerSystem()
        SpeechBubbleSystem.registerSystem()
        CharacterProgressSystem.registerSystem()
        FaderSystem.registerSystem()
        CharacterAudioSystem.registerSystem()
        PlatformOffsetAnimationSystem.registerSystem()
        ButteAmbienceBlendSystem.registerSystem()
        DropShadowSystem.registerSystem()
        FinalRestingPointSystem.registerSystem()
        GamePlayOutroAnimationSystem.registerSystem()
        SquashAnimationSystem.registerSystem()
        IntroParticleAnimationSystem.registerSystem()
        BakedDirectionalLightShadowSystem.registerSystem()
        LevelInputTargetSystem.registerSystem()
        GamePlayStateSystem.registerSystem()
        PortalCrossingSystem.registerSystem()
    }
    
    private func registerComponents() {
        CharacterSpawnPointComponent.registerComponent()
        RockCollectorComponent.registerComponent()
        RockPickupComponent.registerComponent()
        CompoundCollisionMarkerComponent.registerComponent()
        IgnoreCompoundCollisionMarkerComponent.registerComponent()
        CheckpointComponent.registerComponent()
        WinGameTriggerComponent.registerComponent()
        SpeechBubbleTriggerComponent.registerComponent()
        ModelFaderMarkerComponent.registerComponent()
        OpacityFaderComponent.registerComponent()
        PlatformAnimationMarkerComponent.registerComponent()
        FinalRestingPointMarkerComponent.registerComponent()
        IntroParticleAnimationComponent.registerComponent()
        BakedDirectionalLightSourceComponent.registerComponent()
        DirectionalLightFaderComponent.registerComponent()
        LevelInputTargetComponent.registerComponent()
    }

    init() {
        registerSystems()
        registerComponents()
    }

    var body: some SwiftUI.Scene {
        WindowGroup(id: appModel.volumeID) {
            ContentView()
                .environment(appModel)
                .volumeBaseplateVisibility(.hidden)
                .supportedVolumeViewpoints(.front)
                .frame(width: physicalMetrics.convert(CGFloat(GameSettings.volumeSize.width), from: .meters),
                       height: physicalMetrics.convert(CGFloat(GameSettings.volumeSize.height), from: .meters),
                       alignment: .center)
                .frame(depth: physicalMetrics.convert(CGFloat(GameSettings.volumeSize.depth), from: .meters))
        }
        .windowStyle(.volumetric)
        .defaultSize(width: CGFloat(GameSettings.volumeSize.width),
                     height: CGFloat(GameSettings.volumeSize.height),
                     depth: CGFloat(GameSettings.volumeSize.depth), in: .meters)
        .volumeWorldAlignment(.gravityAligned)
        .windowResizability(.contentSize)
    }
}
