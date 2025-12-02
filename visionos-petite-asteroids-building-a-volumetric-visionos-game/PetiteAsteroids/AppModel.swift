/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model the content view observes.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct GameAssetContainer: Component {
    let levels: [GameLevel: Entity]
    let characterAnimationRoot: Entity
}

enum GameLevel {
    case intro
    case main
}

enum AssetType {
    case level(gameLevel: GameLevel)
    case character
    case inputVisualizer
    case audio
}

struct AssetIdentifier {
    let name: String
    let type: AssetType
}

struct LoadResult: Sendable {
    var entity: Entity
    var type: AssetType
}

enum RollInputMode: String, CaseIterable {
    case absolute = "Absolute"
    case relative = "Relative"
    
    var systemImageName: String {
        switch self {
            case .absolute:
                "circle.dashed"
            case .relative:
                "plus.circle.dashed"
        }
    }
}

enum JumpInputMode: String, CaseIterable {
    case look = "Look (Single Input)"
    case pinch = "Pinch (Dual Input)"
    
    var systemImageName: String {
        switch self {
            case .look:
                "eye"
            case .pinch:
                "hand.pinch.fill"
        }
    }

#if targetEnvironment(simulator)
    static let platformDefault: JumpInputMode = .look
#else
    static let platformDefault: JumpInputMode = .pinch
#endif
}

/// Maintains the app-wide state.
@MainActor
@Observable
class AppModel {
    let volumeID = "Volume"
    var isDifficultyHard: Bool = false
    var rollInputMode: RollInputMode = .relative
    var jumpInputMode: JumpInputMode = .platformDefault

    let assetsToLoad: [AssetIdentifier] = [
        AssetIdentifier(name: "Scene", type: .level(gameLevel: .main)),
        AssetIdentifier(name: "Scene_Tutorial_1", type: .level(gameLevel: .intro)),
        AssetIdentifier(name: "Scenes/CharacterRock", type: .character),
        AssetIdentifier(name: "GameAssets/Input_Visualizer", type: .inputVisualizer),
        AssetIdentifier(name: "Audio", type: .audio)
    ]
    var loadingPercentDone: Float = 0
    
    /// The root entity for the `RealityView` scene. Storing this in application
    /// state means any code in the app can get access to it.
    var root = Entity(components: [
        GamePlayStateComponent.loadingAssets,
        LoadingTrackerComponent(),
        GameInfoComponent(currentLevel: .intro),
        AudioCueStorageComponent()
    ])
    /// A descendant of the `root` entity, which acts as the root entity for the current game level.
    var levelRoot = Entity()

    let character = Entity(components: [
        CharacterMovementComponent(),
        CharacterProgressComponent(),
        CharacterAudioComponent()
    ])
    let speechBubble: Entity
    let floorInputTarget = Entity(components: [InputTargetComponent()])
    let backgroundInputTarget = Entity(components: [InputTargetComponent()])
    let handInputVisualizer: Entity = Entity()
    var handInputVisualizerInsidePortal: Entity = Entity()
    let ambientAudioEntity = Entity(components: [AmbientAudioComponent(), ButteAmbienceBlendComponent()])

    let tutorialPromptAttachmentRoot = Entity()
    let tutorialPromptRoll = TutorialPromptDataComponent(
        title: "How to Roll",
        message: [.look: "Pinch and drag to roll around.\nTry rolling over the white dots.",
                  .pinch: "Pinch and drag to roll around.\nTry rolling over the white dots."],
        buttonLabel: nil,
        buttonNotification: nil
    )
    let tutorialPromptJump = TutorialPromptDataComponent(
        title: "How to Jump",
        message: [.look: "Look at and tap where you want to jump.\nTry to reach the dots on the platforms.",
                  .pinch: "Pinch with your other hand to jump.\nTry to reach the dots on the platforms."],
        buttonLabel: nil,
        buttonNotification: nil
    )
    let tutorialPromptComplete = TutorialPromptDataComponent(
        title: "Tutorial Complete",
        message: nil,
        buttonLabel: "Let's start the game.",
        buttonNotification: "TutorialOutro"
    )
    var introSpeechBubbleText: [String] = ["There she is!", "We made it home!", "Hey, stay close!"]
    var outroSpeechBubbleText: [String] = ["Wow, so pretty.", "Maybe there are others like us?", "Let's find out!"]
    var currentIntroSpeechBubbleIndex: Int = 0
    var currentOutroSpeechBubbleIndex: Int = 0
    
    let portalEntity = Entity()
    
    let modelSortGroup = ModelSortGroup()
    
    var menuVisibility: MenuVisibility = .hidden
    
    init() {
        // Prepare the speech bubble.
        speechBubble = Entity(components: [SpeechBubbleComponent(targetEntity: character), BillboardComponent()])
        speechBubble.components.set(ViewAttachmentComponent(rootView: SpeechBubbleAttachmentView(speechBubbleEntity: speechBubble)))
        root.addChild(speechBubble)
        
        // Dispatch a high-priority task to load the game assets in parallel.
        Task.detached(priority: .high) {
            await self.loadGameAssets()
        }
        
        // Add the level root as a descendant of the scene root.
        root.name = "SceneRoot"
        levelRoot.name = "LevelRoot"
        root.addChild(levelRoot)
        
        // Initialize entities.
        character.name = "Character"
        ambientAudioEntity.name = "AmbientAudioEntity"
        
        // Rotation affects ambient audio (but distance doesn't). A gameplay entity can't play ambient audio, so it needs to remain unrotated.
        root.addChild(ambientAudioEntity)
        root.addChild(backgroundInputTarget)
        root.addChild(floorInputTarget)
        
        // Position the level root so that the level's origin is at the bottom of the volume.
        levelRoot.position = [0, -GameSettings.volumeSize.height / 2, GameSettings.levelDepthOffset]
        
        // Create an empty portal world to act as a placeholder until the level assets finish loading.
        let emptyPortalWorld = Entity(components: [WorldComponent()])
        root.addChild(emptyPortalWorld)
        // Create the portal descriptor.
        let portalMeshDescriptor = PortalMeshDescriptor(width: GameSettings.volumeSize.width,
                                                        height: GameSettings.volumeSize.height,
                                                        depth: GameSettings.volumeSize.depth,
                                                        cornerRadius: GameSettings.portalCornerRadius,
                                                        cornerSegmentCount: GameSettings.portalCornerSegmentCount,
                                                        bendRadius: GameSettings.portalBendRadius,
                                                        bendSegmentCount: GameSettings.portalBendSegmentCount)
        // Create the portal.
        portalEntity.name = "PortalEntity"
        portalEntity.components.set(ModelComponent(mesh: generatePortalMesh(descriptor: portalMeshDescriptor), materials: [PortalMaterial()]))
        portalEntity.position = [0, -GameSettings.volumeSize.height / 2, 0]
        portalEntity.components.set(PortalComponent(target: emptyPortalWorld, clippingMode: .disabled, crossingMode: .plane(.positiveY)))
        portalEntity.components.set(OpacityComponent(opacity: 0))
        root.addChild(portalEntity)
        // Create a mesh to block the reverse side of the portal.
        var portalBackerMaterial = SimpleMaterial()
        portalBackerMaterial.faceCulling = .front
        let portalBacker = Entity(components: [ModelComponent(mesh: generatePortalMesh(descriptor: portalMeshDescriptor),
                                                              materials: [portalBackerMaterial])])
        portalEntity.addChild(portalBacker)
    }

    func playLevel(gameLevel: GameLevel, introAnimationConfig: IntroAnimationConfigComponent? = nil) {
        guard let gamePlayAssets = root.components[GameAssetContainer.self],
              let level = gameLevel == .intro ? gamePlayAssets.levels[gameLevel]?.clone(recursive: true) : gamePlayAssets.levels[gameLevel],
              let physicsRoot = level.findEntity(named: "PhysicsRoot"),
              let levelPortalWorldRoot = physicsRoot.findEntity(named: "Level"),
              let spawnPointOrigin = physicsRoot.first(withComponent: CharacterSpawnPointComponent.self)?.entity.parent else {
            return
        }
        
        // Update the game information with the current level.
        let gameInfo = GameInfoComponent(currentLevel: gameLevel)
        let isTutorial = gameInfo.isTutorial
        root.components.set(gameInfo)
        
        // Set the tutorial skip flag when the player progresses beyond the tutorial.
        if isTutorial == false {
            PersistentData().setSkipTutorial(doSkip: true)
        }
        
        // Get the previous level, if there is one.
        let previousLevel = levelRoot.children.first
        
        // Fully prepare the new level if it isn't the same as the previous one.
        if level != previousLevel {
            // Add the new level as a descendant of the level root.
            levelRoot.addChild(level)
            
            // Apply the transform of the previous level's physics root to the current level's physics root.
            if let previousPhysicsRoot = previousLevel?.first(withComponent: PhysicsSimulationComponent.self)?.entity {
                physicsRoot.components.set(previousPhysicsRoot.transform)
                // Also apply the previous rotational camera component.
                if let previousRotationalFollowCamera = previousPhysicsRoot.components[RotationalCameraFollowComponent.self] {
                    physicsRoot.components.set(previousRotationalFollowCamera)
                }
            }
            
            // Add the character as a descendant of the physics root.
            character.setParent(physicsRoot, preservingWorldTransform: true)
            
            // Make the character animation root a descendant of the level portal world so that it can appear within the portal.
            gamePlayAssets.characterAnimationRoot.setParent(levelPortalWorldRoot)

            // Add the hand-input visualizers.
            handInputVisualizer.setParent(physicsRoot)
            handInputVisualizerInsidePortal.setParent(levelPortalWorldRoot)
            
            // Remove the previous level from the level root.
            previousLevel?.removeFromParent()
        }
        
        // Set up the portal to render the level.
        levelPortalWorldRoot.components.set(WorldComponent())
        portalEntity.components[PortalComponent.self]?.targetEntity = levelPortalWorldRoot
        
        // Set up the rotational camera follow if the physics root doesn't already have one.
        if physicsRoot.components.has(RotationalCameraFollowComponent.self) == false {
            let camera = RotationalCameraFollowComponent(followTarget: character,
                                                         cameraZoom: GameSettings.scale,
                                                         followTargetMaxHeight: GameSettings.volumeSize.height,
                                                         cameraVerticalOffsetTop: -GameSettings.volumeSize.height * 0.8)
            physicsRoot.components.set(camera)
        }
        
        // Determine the spawn point Y value to configure the camera component.
        let spawnHeight = spawnPointOrigin.position(relativeTo: physicsRoot).y * GameSettings.scale
        physicsRoot.components[RotationalCameraFollowComponent.self]?.cameraVerticalOffsetBottom = -spawnHeight + GameSettings.characterWorldRadius
        physicsRoot.components[RotationalCameraFollowComponent.self]?.followTargetMinHeight = !isTutorial ?
                                                                                                  spawnHeight + GameSettings.characterWorldRadius :
                                                                                                  GameSettings.volumeSize.height / 2
        
        // Start the intro animation for the level.
        root.components[IntroAnimationConfigComponent.self] = introAnimationConfig
        root.components.set(GamePlayStateComponent.introAnimation)
    }
}
