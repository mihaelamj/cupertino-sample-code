/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that plays sound effects on entities with an audio event component.
*/

import RealityKit
import OSLog

final class AudioEventSystem: System {
    
    required init(scene: Scene) { }
    
    func update(context: SceneUpdateContext) {
        guard let audioResources = context.first(withComponent: AudioResourcesComponent.self)?.component else {
            return
        }
        
        let audioEventEntities = context.entities(matching: .init(where: .has(AudioEventComponent.self)), updatingSystemWhen: .rendering)
        for entity in audioEventEntities {
            guard let event = entity.components[AudioEventComponent.self] else {
                continue
            }
            if let audioResource = audioResources.get(event.resourceName) {
                let controller = entity.prepareAudio(audioResource)
                controller.setVolumePercent(event.volumePercent)
                controller.speed = Double(event.speed)
                controller.play()
            } else {
                logger.error("No audio resource for name: \(event.resourceName)")
            }
            entity.components.remove(AudioEventComponent.self)
        }
    }
}
