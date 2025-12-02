/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App model extensions for loading and preparing game assets.
*/

import SwiftUI
import RealityKit
import RealityKitContent

extension AppModel {
    func loadGameAssets() async {
        // Set the gameplay state to loading assets.
        root.components.set(GamePlayStateComponent.loadingAssets)

        // Run a task group to load all of the assets.
        await withTaskGroup(of: LoadResult.self) { loadAssetsTaskGroup in
            // Add a task to the task group for the loading of each asset.
            for asset in assetsToLoad {
                loadAssetsTaskGroup.addTask {
                    switch asset.type {
                        case .level, .character, .inputVisualizer:
                            guard let entity = try? await Entity(named: asset.name, in: realityKitContentBundle) else {
                                fatalError("Attempted to load entity \(asset.name), but failed.")
                            }
                            return LoadResult(entity: entity, type: asset.type)
                        case .audio:
                        do {
                            let audioResourcesComponent = try await AudioResourcesComponent.load()
                            return await LoadResult(entity: Entity(components: [audioResourcesComponent]), type: asset.type)
                        } catch {
                            fatalError("Attempted to load audio resources, but failed.")
                        }
                    }
                }
            }

            // Prepare the assets as they finish loading.
            let (levels, characterAnimationRoot) = await prepareGameAssets(loadAssetsTaskGroup: loadAssetsTaskGroup)

            // Add the gameplay assets to a container component on the root so the rest of the app can access them.
            guard let characterAnimationRoot else {
                fatalError("Failed to load character animation root.")
            }
            let assetContainerComponent = GameAssetContainer(levels: levels,
                                                             characterAnimationRoot: characterAnimationRoot)
            root.components.set(assetContainerComponent)
        }

        // Set the gameplay state to the loaded assets.
        root.components.set(GamePlayStateComponent.assetsLoaded)
    }
    
    private func prepareGameAssets(loadAssetsTaskGroup: TaskGroup<LoadResult>) async -> (levels: [GameLevel: Entity],
                                                                                         characterAnimationRoot: Entity?) {
        updateLoadingPercentDone(percent: 0)
        var levels: [GameLevel: Entity] = [:]
        var characterAnimationRoot: Entity?
        for await unsafe asset in loadAssetsTaskGroup {
            switch asset.type {
                case .level(let gameLevel):
                    // Prepare the level.
                    prepareLevel(level: asset.entity)
                    levels[gameLevel] = asset.entity
                case .character:
                    // Prepare the character animation root.
                    characterAnimationRoot = asset.entity
                    characterAnimationRoot?.components.set(CharacterAnimationComponent(characterEntityId: self.character.id))
                    characterAnimationRoot?.components.set(PortalCrossingComponent())
                case .inputVisualizer:
                    // Prepare the input visualizer.
                    prepareInputVisualizer(inputVisualizer: asset.entity)
                case .audio:
                    // Add the entity with the audio resources component to the scene.
                    root.addChild(asset.entity)
            }
            updateLoadingPercentDone(percent: loadingPercentDone + 1.0 / Float(assetsToLoad.count))
        }
        updateLoadingPercentDone(percent: 1)
        return (levels, characterAnimationRoot)
    }
    
    private func updateLoadingPercentDone(percent: Float) {
        withAnimation {
            loadingPercentDone = percent
        }
    }
    
    private func prepareInputVisualizer(inputVisualizer: Entity) {
        guard let (directionIndicator, directionIndicatorModelComponent) = inputVisualizer.first(withComponent: ModelComponent.self),
              var material = directionIndicatorModelComponent.materials[0] as? ShaderGraphMaterial else {
            return
        }
        // Prepare a material for the input visualizers that renders on top of other meshes.
        material.readsDepth = false
        material.writesDepth = false
        
        // Prepare the direction indicator.
        directionIndicator.name = "DirectionIndicator"
        directionIndicator.components[ModelComponent.self]?.materials[0] = material
        directionIndicator.components.set(ModelSortGroupComponent(group: modelSortGroup, order: 50))
        directionIndicator.scale = SIMD3<Float>(repeating: 0.5)
        
        // Add the blend shape weights component.
        let blendShapeWeightsMapping = BlendShapeWeightsMapping(meshResource: directionIndicatorModelComponent.mesh)
        let blendWeightShapesComponent = BlendShapeWeightsComponent(weightsMapping: blendShapeWeightsMapping)
        directionIndicator.components.set(blendWeightShapesComponent)
        
        // Create the jump indicator.
        let jumpIndicator = Entity(components: [
            ModelComponent(mesh: .generateSphere(radius: 0.25), materials: [material]),
            ModelSortGroupComponent(group: modelSortGroup, order: 50)
        ])
        jumpIndicator.name = "JumpIndicator"
        
        // Set up the hand-input visualizer.
        handInputVisualizer.components.set(OpacityComponent(opacity: 0.85))
        handInputVisualizer.addChild(directionIndicator)
        handInputVisualizer.addChild(jumpIndicator)
        handInputVisualizer.name = "HandInputVisualizer"
        handInputVisualizer.components.set(InputVisualizerComponent(character: character,
                                                                        directionIndicator: directionIndicator,
                                                                        jumpIndicator: jumpIndicator))
        
        // Set up the duplicate hand-input visualizer inside the portal.
        handInputVisualizerInsidePortal = handInputVisualizer.clone(recursive: true)
        guard let directionIndicatorCopy = handInputVisualizerInsidePortal.findEntity(named: directionIndicator.name),
              let jumpIndicatorCopy = handInputVisualizerInsidePortal.findEntity(named: jumpIndicator.name) else {
            return
        }
        handInputVisualizerInsidePortal.components[InputVisualizerComponent.self]?.directionIndicator = directionIndicatorCopy
        handInputVisualizerInsidePortal.components[InputVisualizerComponent.self]?.jumpIndicator = jumpIndicatorCopy
    }
    
    private func prepareLevel(level: Entity) {
        // Find the required entities in the scene.
        guard let physicsRoot = level.findEntity(named: "PhysicsRoot") else {
            return
        }
        
        // Prepare the physics root.
        physicsRoot.components.set(PhysicsSimulationComponent())

        // Override the group of all model sort group components so that they share the same group across levels with the hand-input visualizer.
        physicsRoot.forEachDescendant(withComponent: ModelSortGroupComponent.self) { entity, _ in
            entity.components[ModelSortGroupComponent.self]?.group = modelSortGroup
        }
    }
}
