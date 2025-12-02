/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object to respond to player interactions and update gameplay.
*/
import RealityKit
import TabletopKit
import Spatial

class GameInteraction: TabletopInteraction.Delegate {
    let game: Game
    
    init(game: Game) {
        self.game = game
    }
    
    func update(interaction: TabletopKit.TabletopInteraction) {

    }
}

class PlayerInteraction: GameInteraction, @unchecked Sendable {
    override func update(interaction: TabletopInteraction) {
        // A gesture interaction to aim the jump.
        if interaction.value.gesture != nil || interaction.value.startingEquipmentID != interaction.value.controlledEquipmentID {
            updateGestureInteraction(interaction: interaction)
            return
        }
        
        // A programmatic interaction for the jump after the player releases the aim.
        updateProgrammaticInteraction(interaction: interaction)
    }
        
    func updateGestureInteraction(interaction: TabletopInteraction) {
        guard let gesture = interaction.value.gesture else { return }
        if gesture.phase == .started {
            guard let player = game.tabletopGame.equipment(matching: interaction.value.startingEquipmentID) as? Player else { return }
            interaction.setControlledEquipment(matching: .aimingSightID(for: player.seat))
            return
        }
        
        if gesture.phase == .update {
            // Update the slingshot visuals while the player is still dragging.
            game.tabletopGame.withCurrentSnapshot { snapshot in
                guard let (playerEquip, _) = snapshot.equipment(of: Player.self, matching: interaction.value.startingEquipmentID) else { return }
                let aimX = interaction.value.pose.position.x
                let aimZ = interaction.value.pose.position.z
                let root = game.renderer.root
                Task { @MainActor in
                    playerEquip.updateAimingVisuals(dragPosition: .init(x: aimX, z: aimZ), root: root)
                }
            }
            return
        }
        
        if gesture.phase == .ended {
            // When the player releases the aim, hide the aiming visuals and start a programmatic interaction for the jump.
            game.tabletopGame.withCurrentSnapshot { snapshot in
                if let (playerEquip, _) = snapshot.equipment(of: Player.self, matching: interaction.value.startingEquipmentID) {
                    Task { @MainActor in
                        playerEquip.hideAimingVisuals()
                    }
                }
                
                guard let interactionIdentifier = game.tabletopGame.startInteraction(onEquipmentID: interaction.value.startingEquipmentID) else {
                    return
                }
                guard let (playerEquip, _) = snapshot.equipment(of: Player.self, matching: interaction.value.startingEquipmentID) else { return }
                
                let targetX = interaction.value.pose.position.x
                let targetZ = interaction.value.pose.position.z
                let root = game.renderer.root
                Task { @MainActor in
                    game.programmaticPlayerInteractions[interactionIdentifier] = playerEquip.calcTargetPose(
                        dragPosition: .init(x: targetX, z: targetZ),
                        root: root
                    )
                    playerEquip.playJumpAudio()
                }
            }
            return
        }
    }
        
    func updateProgrammaticInteraction(interaction: TabletopInteraction) {
        if interaction.value.phase == .started {
            interaction.setConfiguration(.init(allowedDestinations: .restricted(.allStones + .allLilyPads + .allLogs)))
            return
        }
        
        if interaction.value.phase == .update {
            guard let targetPose = game.programmaticPlayerInteractions[interaction.value.id] else { return }
            let oldPose = interaction.value.pose
            
            if abs(oldPose.position.x - targetPose.position.x) < 1e-3 && abs(oldPose.position.z - targetPose.position.z) < 1e-3 {
                if interaction.value.proposedDestination == nil {
                    sinkPlayer(interaction: interaction, targetPose: targetPose)
                    return
                }
                interaction.setPose(targetPose)
                interaction.end()
                return
            }
            movePlayer(interaction: interaction, targetPose: targetPose)
            return
        }
        
        if interaction.value.phase == .ended {
            endJump(interaction: interaction)
        }
    }
    
    func movePlayer(interaction: TabletopInteraction, targetPose: Pose3D) {
        let oldPose = interaction.value.pose
        let delta = 0.005
        var moveDirection = targetPose.position - oldPose.position
        moveDirection.y = 0
        if moveDirection.length < delta {
            interaction.setPose(targetPose)
            return
        }
        let positionDelta = delta * moveDirection.normalized
        let pose = Pose3D(position: oldPose.position.translated(by: positionDelta), rotation: targetPose.rotation)
        interaction.setPose(pose)
    }
    
    func sinkPlayer(interaction: TabletopInteraction, targetPose: Pose3D) {
        let oldPose = interaction.value.pose
        let minY = -0.03
        let sinkDelta = sqrt(oldPose.position.y - minY) * 0.001
        var sinkingTargetPose = targetPose
        interaction.setConfiguration(.init(allowedDestinations: .restricted([]), hoverAlignment: .disabled))
        
        if oldPose.position.y < minY {
            interaction.end()
            return
        }
        
        sinkingTargetPose.position.y = oldPose.position.y - sinkDelta
        interaction.setPose(sinkingTargetPose)
    }
    
    func endJump(interaction: TabletopInteraction) {
        if let proposedDestination = interaction.value.proposedDestination {
            // Move the player to the proposed destination.
            interaction.addAction(.moveEquipment(matching: interaction.value.controlledEquipmentID,
                                                 childOf: proposedDestination.equipmentID, pose: proposedDestination.pose))
            
            // If the destination is a lily pad, sink it.
            if game.tabletopGame.equipment(of: LilyPad.self, matching: proposedDestination.equipmentID) != nil {
                _ = game.tabletopGame.startInteraction(onEquipmentID: proposedDestination.equipmentID)
            }
            
            // If the destination contains an uncollected coin, collect it.
            game.tabletopGame.withCurrentSnapshot { snapshot in
                if let childId = snapshot.equipmentIDs(childrenOf: proposedDestination.equipmentID).first,
                   let coinState = snapshot.state(matching: childId) as? CoinState {
                    if !coinState.collected {
                        interaction.addAction(CollectCoin(playerId: interaction.value.controlledEquipmentID, coinId: childId))
                    }
                }
            }
            game.programmaticPlayerInteractions.removeValue(forKey: interaction.value.id)
            return
        }
        // If the player doesn't land on a valid destination, return them to their starting position.
        let player = game.tabletopGame.equipment(of: Player.self, matching: interaction.value.controlledEquipmentID)!
        interaction.addAction(.moveEquipment(matching: player.id, childOf: .bankID(for: player.seat), pose: .identity))
        interaction.addAction(DecrementHealth(playerId: interaction.value.controlledEquipmentID))
        game.programmaticPlayerInteractions.removeValue(forKey: interaction.value.id)
    }
}

class LogInteraction: GameInteraction {
    let deltaLength = 0.0005
    
    override func update(interaction: TabletopInteraction) {
        // Disallow gesture interactions.
        guard interaction.value.gesture == nil else { return }
        
        if interaction.value.phase == .update {
            guard let controlledLog = game.tabletopGame.equipment(matching: interaction.value.controlledEquipmentID) as? Log else { return }
            let oldPose = interaction.value.pose
            let newPose = calcNewPose(oldPose: oldPose, movementParams: controlledLog.movementParams)
            interaction.setPose(newPose)
        }
    }

    func calcNewPose(oldPose: Pose3D, movementParams: Log.MovementParams) -> Pose3D {
        if let cornerNewPose = calcCornerNewPose(oldPose: oldPose, movementParams: movementParams) {
            return cornerNewPose
        }
        
        let directionMultiplier = movementParams.clockwise ? -1.0 : 1.0
        var deltaX = 0.0 // Position displacement along the x-axis
        var deltaZ = 0.0 // Position displacement along the z-axis
        
        var newPose = oldPose
        
        // Return a new pose for the top edge.
        if abs(oldPose.position.z - movementParams.topLeft.z) < 1e-3 {
            deltaX -= deltaLength
            deltaX *= directionMultiplier
            newPose.position.x += deltaX
            newPose.position.z = movementParams.topLeft.z
            return newPose
        }
        
        // Return a new pose for the left edge.
        else if abs(oldPose.position.x - movementParams.topLeft.x) < 1e-3 {
            deltaZ += deltaLength
            deltaZ *= directionMultiplier
            newPose.position.x = movementParams.topLeft.x
            newPose.position.z += deltaZ
            return newPose
        }
        
        // Return a new pose for the bottom edge.
        else if abs(oldPose.position.z - movementParams.bottomRight.z) < 1e-3 {
            deltaX += deltaLength
            deltaX *= directionMultiplier
            newPose.position.x += deltaX
            newPose.position.z = movementParams.bottomRight.z
            return newPose
        }
        
        // Return a new pose for the right edge.
        else if abs(oldPose.position.x - movementParams.bottomRight.x) < 1e-3 {
            deltaZ -= deltaLength
            deltaZ *= directionMultiplier
            newPose.position.x = movementParams.bottomRight.x
            newPose.position.z += deltaZ
            return newPose
        }
        return oldPose
    }
    
    func calcCornerNewPose(oldPose: Pose3D, movementParams: Log.MovementParams) -> Pose3D? {
        var isCorner = false
        // Check whether the pose is at the top-left corner.
        if abs(oldPose.position.x - movementParams.topLeft.x) < movementParams.cornerRadius
            && abs(oldPose.position.z - movementParams.topLeft.z) < movementParams.cornerRadius {
            isCorner = true
        }
        
        // Check whether the pose is at the bottom-left corner.
        if abs(oldPose.position.x - movementParams.topLeft.x) < movementParams.cornerRadius
            && abs(oldPose.position.z - movementParams.bottomRight.z ) < movementParams.cornerRadius {
            isCorner = true
        }
        
        // Check whether the pose is at the bottom-right corner.
        if abs(oldPose.position.x - movementParams.bottomRight.x) < movementParams.cornerRadius
            && abs(oldPose.position.z - movementParams.bottomRight.z ) < movementParams.cornerRadius {
            isCorner = true
        }
        
        // Check whether the pose is at the top-right corner.
        if abs(oldPose.position.x - movementParams.bottomRight.x) < movementParams.cornerRadius
            && abs(oldPose.position.z - movementParams.topLeft.z) < movementParams.cornerRadius {
            isCorner = true
        }
        
        if !isCorner { return nil }
        
        let directionMultiplier = movementParams.clockwise ? -1.0 : 1.0
        var deltaX = 0.0 // Position displacement along the x-axis
        var deltaZ = 0.0 // Position displacement along the z-axis
        var deltaAngle = 0.0 // Angular displacement around the y-axis
        
        deltaAngle = deltaLength / movementParams.cornerRadius
        deltaAngle *= directionMultiplier
        (deltaX, deltaZ) = calcDelta(pose: oldPose,
                                     movementParams: movementParams,
                                     deltaAngle: deltaAngle,
                                     directionMultiplier: directionMultiplier)
        
        var newPose = oldPose
        newPose.position.x += deltaX
        newPose.position.z += deltaZ
        var newAngle = newPose.rotation.angle.radians + deltaAngle
        if newAngle >= .pi * 2 {
            newAngle -= .pi * 2
        }
        if newAngle < 0 {
            newAngle += .pi * 2
        }
        newPose.rotation = .Rotation(angle: .radians(newAngle), axis: .y)
        
        return newPose
    }
    
    func calcDelta(pose: Pose3D, movementParams: Log.MovementParams, deltaAngle: Double, directionMultiplier: Double) -> (Double, Double) {
        let currAngle = pose.rotation.angle.radians
        var deltaX = movementParams.cornerRadius * sin(.radians(deltaAngle + currAngle))
        deltaX -= movementParams.cornerRadius * sin(.radians(currAngle))
        deltaX *= -1
        var deltaZ = movementParams.cornerRadius - movementParams.cornerRadius * cos(.radians(deltaAngle + currAngle))
        deltaZ -= movementParams.cornerRadius - movementParams.cornerRadius * cos(.radians(currAngle))
        
        return (deltaX, deltaZ)
    }
}

class LilyPadInteraction: GameInteraction {
    override func update(interaction: TabletopInteraction) {
        // Disallow gesture interactions.
        guard interaction.value.gesture == nil else { return }
        
        if interaction.value.phase == .started {
            game.lilyPadSinkStates[interaction.value.startingEquipmentID] = .started
            return
        }
        
        if interaction.value.phase == .update {
            guard let timer = game.lilyPadSinkTimers[interaction.value.startingEquipmentID] else { return }
            guard let sinkState = game.lilyPadSinkStates[interaction.value.startingEquipmentID] else { return }
            
            let sinkHeight = 0.02
            let sinkTime = 3.0
            
            // Set the lily pad's y-position based on the value of the timer.
            if timer < sinkTime {
                var pose = interaction.value.initialPose
                pose.position.y -= sinkHeight * (timer / sinkTime)
                interaction.setPose(pose)
            }
            
            // After reaching `sinkTime`, start floating the lily pad back up.
            if timer >= sinkTime {
                // If there are any players on the lily pad, return them to their starting positions.
                game.tabletopGame.withCurrentSnapshot { snapshot in
                    for childId in snapshot.equipmentIDs(childrenOf: interaction.value.startingEquipmentID) {
                        guard let player = game.tabletopGame.equipment(of: Player.self, matching: childId) else { continue }
                        interaction.addAction(.moveEquipment(matching: player.id, childOf: .bankID(for: player.seat), pose: .identity))
                        interaction.addAction(DecrementHealth(playerId: player.id))
                    }
                }
                
                var pose = interaction.value.initialPose
                pose.position.y -= sinkHeight
                interaction.setPose(pose)
                interaction.addAction(SinkLilyPad(lilyPadId: interaction.value.startingEquipmentID))
                game.lilyPadSinkStates[interaction.value.startingEquipmentID] = .sank
            }
            
            // When the timer is zero, reset the lily pad to the idle state and end this interaction.
            if timer <= 0 && sinkState == .sank {
                game.lilyPadSinkStates[interaction.value.startingEquipmentID] = .idle
                interaction.setPose(interaction.value.initialPose)
                interaction.addAction(ResetLilyPad(lilyPadId: interaction.value.startingEquipmentID))
                interaction.end()
            }
        }
    }
    
}
