/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object to respond to player interactions and update gameplay.
*/
import RealityKit
import TabletopKit
import Spatial

class DiceInteraction: TabletopInteraction.Delegate {
    
    // The game container.
    let game: Game
    
    // A Boolean value that indicates whether the game always roll the highest score.
    let predeterminedOutcome: Bool
    
    // The die that the player controls.
    var controlledDie: Die
    
    // The extra die to toss.
    var extraDiceToToss: [Die] = []

    init(game: Game,
         predeterminedOutcome: Bool,
         tossAllDice: Bool,
         initialInteractionValue: TabletopInteraction.Value) {
        self.game = game
        self.predeterminedOutcome = predeterminedOutcome
        
        self.controlledDie = game.tabletopGame.equipment(of: Die.self,
                                                         matching: initialInteractionValue.controlledEquipmentID)!
        
        if tossAllDice {
            extraDiceToToss = game.tabletopGame.equipment.compactMap { equipment in
                if equipment.id == controlledDie.id {
                    return nil
                }
                return equipment as? Die
            }
        }
    }
    
    func update(interaction: TabletopInteraction) {
        switch interaction.value.phase {
        case .started:
            // If the player tosses extra dice, parent them around the controlled
            // die so that they move together as the hand moves.
            for (index, die) in extraDiceToToss.enumerated() {
                interaction.addAction(.moveEquipment(die,
                                                     childOf: controlledDie,
                                                     pose: hexagonPoses[index]))
            }
            
        case .update:
            if interaction.value.gesture?.phase == .ended {
                // Toss the dice when the gesture ends.
                interaction.toss(equipmentID: controlledDie.id,
                                 as: controlledDie.tossableRepresentation)
                
                for die in extraDiceToToss {
                    interaction.toss(equipmentID: die.id,
                                     as: die.tossableRepresentation)
                }
            }
            
        case .ended:
            if interaction.value.phase == .ended {
                // Update the score for the last toss when the toss ends.
                game.updateLastRollScore(for: [controlledDie] + extraDiceToToss)
            }
            
        default:
            break
        }
    }
    
    // The toss is starting and the app received the outcome of the physics
    // simulation. Commit this data to the equipment state so when the tos ends,
    // the dice stays exactly as the simulation left them.
    //
    // This is also an appropriate place to force a different outcome, like
    // `predeterminedOutcome`.
    func onTossStart(interaction: TabletopInteraction,
                     outcomes: [TabletopInteraction.TossOutcome]) {
        
        let allTossedDice = [controlledDie] + extraDiceToToss
        
        for outcome in outcomes {
            guard let die = allTossedDice.first(where: { $0.id == outcome.id }) else {
                fatalError("Outcome ID \(outcome.id) does not match any of the tossed dice")
            }
            
            let face = if predeterminedOutcome {
                die.faceWithHighestScore()
            } else {
                // Roll the score that the physics simulation determines.
                outcome.tossableRepresentation.face(for: outcome.restingOrientation)
            }
            
            // Set the new final pose and score on the die.
            interaction.addAction(.updateEquipment(die,
                                                   rawValue: face.rawValue,
                                                   pose: outcome.pose))
            
            if die.id != controlledDie.id {
                // If this was one of the extra dice, ensure that its pose is
                // back in table space.
                interaction.addAction(.moveEquipment(matching: die.id,
                                                     childOf: .tableID))
            }
        }
    }
}

private let hexagonPoses: [TableVisualState.Pose2D] = {
    let radius = 0.1
    let height = radius * sqrt(3) / 2
    
    return [
        .init(position: .init(x: radius / 2, z: height), rotation: .zero),
        .init(position: .init(x: radius, z: 0), rotation: .zero),
        .init(position: .init(x: radius / 2, z: -height), rotation: .zero),
        .init(position: .init(x: -radius / 2, z: height), rotation: .zero),
        .init(position: .init(x: -radius, z: 0), rotation: .zero),
        .init(position: .init(x: -radius / 2, z: -height), rotation: .zero)
    ]
}()
