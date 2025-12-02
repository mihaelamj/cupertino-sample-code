/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that implements the tabletop game.
*/

import SwiftUI
import RealityKit
import TabletopKit

@Observable
class Playground: EntityRenderDelegate {
    let game: TabletopGame
    let table = Table()
    let root = Entity()
    let cursor: Entity

    @MainActor
    init() {
        let table = Table()

        cursor = createCursor(width: 0.02, depth: 0.02, color: .yellow, parent: root)

        var setup = TableSetup(tabletop: table)
        setup.add(seat: Seat(index: 0, position: .init(x: 0, z: -0.5)))
        setup.add(seat: Seat(index: 1, position: .init(x: 0, z: +0.5)))
        setup.add(equipment: MessyPile(index: .messyPileId, position: .init(x: 0, z: 0)))
        setup.add(equipment: Stack(index: .stackPileId, position: .init(x: 0, z: 0.26)))
        
        for idx in 0 ..< 52 {
            setup.add(equipment: Card(index: idx + 3, position: .zero, parent: .stackPileId))
        }

        game = TabletopGame(tableSetup: setup)
        game.debugDraw(options: [.drawEquipment, .drawTable])
        game.claimAnySeat()
        game.addRenderDelegate(self)
    }

    func onUpdate(timeInterval: Double, snapshot: TableSnapshot, visualState: TableVisualState) {
        if let playerCursor = snapshot.cursors(for: game.localPlayer).first,
           let pose = playerCursor.hovering?.pose3D(snapshot: snapshot, visualState: visualState) {
            cursor.transform = .init(pose: pose)
            cursor.isEnabled = true
        } else {
            cursor.isEnabled = false
        }
    }
}

// MARK: - Utility

extension TabletopInteraction.Destination {
    func pose3D(snapshot: TableSnapshot, visualState: TableVisualState) -> Pose3D {
        let position = Point3D(x: pose.position.x, y: 0, z: pose.position.z)
        let rotation = Rotation3D(angle: pose.rotation, axis: .y)

        let childToParent = Pose3D(position: position, rotation: rotation)
        var parentToTable = Pose3D.identity

        if let equipmentBounds = visualState.bounds(matching: equipmentID) {
            parentToTable = equipmentBounds.pose

            // Special handling of a flipped card. The `visualState` transform has
            // the card's resting orientation applied, but the cursor should not
            // since layout happens in the un-oriented space.
            if let (card, cardState) = snapshot.equipment(of: Card.self, matching: equipmentID) {
                let restingOrientation = card.restingOrientation(state: cardState)
                parentToTable.rotation *= restingOrientation.inverse
            }
        }

        return childToParent * parentToTable
    }
}

extension Transform {
    init(pose: Pose3D) {
        self.init(rotation: simd_quatf(vector: simd_float(pose.rotation.vector)), translation: simd_float(pose.position.vector))
    }
}

func createCursor(width: Float, depth: Float, color: UIColor, parent: Entity) -> Entity {
    let mesh = MeshResource.generateBox(width: width, height: 0.03, depth: depth)
    let entity = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: color)])

    parent.addChild(entity)

    return entity
}
