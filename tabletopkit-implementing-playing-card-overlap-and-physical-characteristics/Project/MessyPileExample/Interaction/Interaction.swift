/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure for implementing an interaction with a tabletop game.
*/

import SwiftUI
import RealityKit
import TabletopKit

struct Interaction: TabletopInteraction.Delegate {
    var game: TabletopGame

    init(game: TabletopGame) {
        self.game = game
    }

    func update(interaction: TabletopInteraction) {
        if interaction.value.gesture?.phase == .started {
            var configuration = interaction.value.configuration
            configuration.allowedDestinations = .restricted([.tableID, .messyPileId, .stackPileId])
            interaction.setConfiguration(configuration)

            // Remove the card from the current owner when a player picks it up,
            // so the layout of remaining descendants immediately adjusts.
            // If this interaction ends by gesture cancel, the game undoes this move,
            // returning the card to its original location.
            game.withCurrentSnapshot { snapshot in
                let equipment = interaction.value.controlledEquipmentID
                if game.equipment(of: Card.self, matching: equipment) != nil {
                    let poseOffTable = TableVisualState.Pose2D(position: .init(x: -1.0, z: -1.0), rotation: .zero)
                    interaction.addAction(.moveEquipment(matching: equipment, childOf: .tableID, pose: poseOffTable))
                }
            }
        }
        
        if interaction.value.phase == .ended {
            game.withCurrentSnapshot { snapshot in
                let equipment = interaction.value.controlledEquipmentID
                if interaction.value.proposedFlip == true {
                    if let card = game.equipment(of: Card.self, matching: equipment) {
                        interaction.addAction(.updateEquipment(card, faceUp: !snapshot.state(for: card).faceUp))
                    }
                }
                if let destination = interaction.value.proposedDestination {
                    interaction.addAction(.moveEquipment(matching: equipment, childOf: destination.equipmentID, pose: destination.pose))
                }
            }
        }
    }
}
