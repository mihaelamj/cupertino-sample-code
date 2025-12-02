/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Renders objects other than equipment.
*/
import RealityKit
import SwiftUI
import TabletopKit
import RealityKitContent

@MainActor @Observable
class GameRenderer:
    @preconcurrency TabletopGame.RenderDelegate {
    let root: Entity
    weak var game: Game?
    
    var iblEntity = Entity()

    @MainActor
    init() {
        root = Entity()
        root.transform.translation = .init(x: 0, y: -0.1, z: 0)
        
        Task {
            let studioIbl = try await EnvironmentResource(named: "small_harbor_02_2k", in: Bundle.main)
            var iblComp = ImageBasedLightComponent(source: .single(studioIbl))
            iblComp.inheritsRotation = true
            iblComp.intensityExponent = -2
            iblEntity.components.set(iblComp)
            iblEntity.setParent(root)
            root.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblEntity))
        }
    }
    
    func onUpdate(timeInterval: Double, snapshot: TableSnapshot, visualState: TableVisualState) {
        guard let game = game else { return }
        
        // Update the lily pad's sink timers with `timeInterval`.
        for lilyPadSinkState in game.lilyPadSinkStates {
            let id = lilyPadSinkState.key
            let sinkState = lilyPadSinkState.value
            
            // Increase the timer when the lily pad is sinking down; decrease it when the lily pad is floating back up.
            switch sinkState {
            case .idle:
                game.lilyPadSinkTimers[id]! = 0
            case .started:
                game.lilyPadSinkTimers[id]! += timeInterval
            case .sank:
                game.lilyPadSinkTimers[id]! -= timeInterval
            }
        }
    }
}
