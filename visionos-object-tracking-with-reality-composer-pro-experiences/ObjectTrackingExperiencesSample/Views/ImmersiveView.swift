/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Integrates RealityKit to create an interactive AR experience, it manages
 various entities and game states for a dynamic keyboard-based game with
 Object Tracking interactions.
*/
import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ImmersiveView: View {
    @State private var rootEntity: Entity!
    @State private var anchorEntity: Entity!
    @State private var occlusionEntity: Entity!
    @State private var targetEntity: Entity!
    @State private var scenesParentEntity: Entity!
    @State private var labelsParentEntity: Entity!
    @State private var currentSceneEntity: Entity!
    @State private var returnKeyEntity: Entity!
    @State private var pinEntity: Entity!
    @State private var pinInitialPosition = SIMD3<Float>()
    @State private var mainLabelText = ""
    @State private var secondaryLabelText = ""
    @State private var typedText = ""
    @State private var returnKeyCollisionSubscription: EventSubscription!
    @State private var objectTrackingGuide: ObjectTrackingGuide!

    @Environment(AppModel.self) private var appModel

    private let game = KeyboardGame()
    private let labelsID = "mainLabelId"
    private let lookAroundLabelsID = "lookAroundLabelId"
    private let lookAroundText = "Look around for this object"
    private let anchorEntityName = "Anchor"
    private let targetEntityName = "Target"
    private let occlusionEntityName = "OcclusionKeyboard"
    private let scenesParentName = "ScenesParent"
    private let labelsParentName = "LabelsParent"
    private let returnKeyName = "RETURN"
    private let deleteKeyName = "DELETE"
    private let pinEntityName = "PushPin"
    private let magicKeyboardRefObjPath = "Geometry/MagicKeyboard"

    var body: some View {
        RealityView { content, attachments in
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
                setupEntities(content, rootEntity: immersiveContentEntity)
                setupAttachments(attachments)
                await setupGuide(content, attachments: attachments)
                observeReturnKeyCollisions(content)
                game.startGame()
                updateScene()
            }
        }
        attachments: {
            Attachment(id: labelsID) {
                VStack(spacing: 10.0) {
                    Label(mainLabelText, systemImage: "")
                        .labelStyle(.titleOnly)
                        .frame(width: 400)
                    Label(secondaryLabelText, systemImage: "")
                        .labelStyle(.titleOnly)
                        .frame(width: 400)
                        .font(.system(size: 12.0))
                        .foregroundColor(.yellow)
                    Label(typedText, systemImage: "")
                        .labelStyle(.titleOnly)
                        .font(.system(size: 10.0))
                        .foregroundColor(.purple)
                }
            }
            Attachment(id: lookAroundLabelsID) {
                HStack {
                    Text(lookAroundText)
                }
            }
        }
        .gesture(
            DragGesture().targetedToAnyEntity().onChanged({ event in
                guard let entityParent = event.entity.parent else { return }
                event.entity.position = event.convert(event.location3D, from: .local, to: entityParent)
            })
        )
        .gesture(
            TapGesture().targetedToAnyEntity().onEnded({ event in
                onKeyTap(entity: event.entity)
            })
        )
        .task {
            FadeOutSystem.registerSystem()
        }
    }
    
    private func setupEntities(_ content: RealityViewContent, rootEntity: Entity) {
        self.rootEntity = rootEntity
        anchorEntity = rootEntity.findEntity(named: anchorEntityName)
        occlusionEntity = rootEntity.findEntity(named: occlusionEntityName)
        targetEntity = rootEntity.findEntity(named: targetEntityName)
        scenesParentEntity = rootEntity.findEntity(named: scenesParentName)
        labelsParentEntity = rootEntity.findEntity(named: labelsParentName)
        returnKeyEntity = rootEntity.findEntity(named: returnKeyName)
        pinEntity = rootEntity.findEntity(named: pinEntityName)
        pinInitialPosition = pinEntity.position
    }
    
    private func setupAttachments(_ attachments: RealityViewAttachments) {
        if let mainLabelEntity = attachments.entity(for: labelsID) {
            mainLabelEntity.position = [0, 0.2, 0]
            labelsParentEntity.addChild(mainLabelEntity)
        } else {
            assertionFailure("Main label isn't available as an attachment")
        }
    }
    
    private func onKeyTap(entity: Entity) {
        let enableEmitterDelayInSeconds = 1.5
        Self.enableEmitter(true, in: entity, toggleIn: enableEmitterDelayInSeconds)
        guard !game.isPaused, let challengeInput = game.currentChallenge?.playerInput else { return }
        if case .word(_) = challengeInput {
            entity.name == deleteKeyName ? _ = typedText.removeLast() : typedText.append(entity.name)
        }
        if let playerInput = createPlayerInput(from: challengeInput, inputKeyName: entity.name, typedText: self.typedText),
            game.respond(playerInput) {
            updateScene()
        }
    }
    
    private func createPlayerInput(from challengeInput: PlayerInput, inputKeyName: String, typedText: String) -> PlayerInput? {
        if case .letter(_) = challengeInput {
            return .letter(inputKeyName)
        } else if case .word(_) = challengeInput {
            return .word(typedText)
        } else if case .anyKey = challengeInput {
            return .anyKey
        }
        return nil
    }
    
    private func updateScene() {
        typedText = ""
        mainLabelText = game.currentChallenge?.description ?? ""
        secondaryLabelText = game.currentChallenge?.instructions ?? ""
        showCurrentScene()
    }
    
    private func observeReturnKeyCollisions(_ content: RealityViewContent) {
        returnKeyCollisionSubscription = content.subscribe(to: CollisionEvents.Began.self, on: returnKeyEntity) { event in
            guard !game.isPaused else { return }
            if event.entityA == pinEntity || event.entityB == pinEntity {
                handlePinOnReturnKey()
            }
        }
    }
    
    private func handlePinOnReturnKey() {
        game.isPaused = true
        Self.showEmitter(true, in: currentSceneEntity)
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            Self.showEmitter(false, in: currentSceneEntity)
            pinEntity.position = pinInitialPosition
            let playerInput: PlayerInput = .keyCollision(returnKeyName)
            game.respond(playerInput)
            updateScene()
            game.isPaused = false
        }
    }
    
    private func showCurrentScene() {
        guard let currentChallenge = game.currentChallenge else { return }
        Task {
            currentSceneEntity?.setOpacity(0.0)
            if let sceneName = currentChallenge.sceneName,
               let sceneEntity = scenesParentEntity.children.first(where: { $0.name == sceneName }) {
                sceneEntity.setOpacity(1.0)
                currentSceneEntity = sceneEntity
            }
        }
    }
    
    static private func enableEmitter(_ enabled: Bool, in entity: Entity, toggleIn delayInSeconds: Double? = nil) {
        guard let emitterEntity = entity.findEntity(named: "Emitter"),
              var emitterComponent = emitterEntity.components[ParticleEmitterComponent.self] else { return }
        emitterComponent.isEmitting = enabled
        entity.components.set(emitterComponent)
        guard let delayInSeconds else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(delayInSeconds)) {
            emitterComponent.isEmitting = !enabled
            entity.components.set(emitterComponent)
        }
    }
    
    static private func showEmitter(_ show: Bool, in entity: Entity) {
        guard let emitterEntity = entity.findEntity(named: "Emitter") else { return }
        emitterEntity.setOpacity(show ? 1.0 : 0.0)
    }
    
    private func setupGuide(_ content: RealityViewContent, attachments: RealityViewAttachments) async {
        guard let guideEntity = try? await Entity(named: magicKeyboardRefObjPath, in: realityKitContentBundle) else {
            fatalError("Could not create model entity from \(magicKeyboardRefObjPath) file")
        }
        guard let lookAroundLabelEntity = attachments.entity(for: lookAroundLabelsID) else { return }
        targetEntity.setOpacity(0.0)
        guideEntity.orientation = simd_quatf(angle: (Float.pi * 0.2), axis: SIMD3<Float>(1, 0, 0))
        objectTrackingGuide = await ObjectTrackingGuide(content: content, anchorEntity: anchorEntity,
                                                             guideEntity: guideEntity, guideTextEntity: lookAroundLabelEntity,
                                                             targetEntity: occlusionEntity) {
            targetEntity.setOpacity(1.0)
        }
        let initialState = appModel.immersiveSpaceState
        appModel.immersiveSpaceState = .inTransition
        await objectTrackingGuide.show()
        appModel.immersiveSpaceState = initialState
    }
}

extension Entity {
    func setOpacity(_ opacity: Float) {
        if var opacityComponent = components[OpacityComponent.self] {
            opacityComponent.opacity = opacity
            components.set(opacityComponent)
        } else {
            components.set(OpacityComponent(opacity: opacity))
        }
    }
}
