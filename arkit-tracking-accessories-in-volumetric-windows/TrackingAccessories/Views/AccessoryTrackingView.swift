/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A volumetric window where the apps runs accessory tracking.
*/

import SwiftUI
import RealityKit
import ARKit

struct AccessoryTrackingView: View {
    @State private var model = AccessoryTrackingModel()
    
    @State private var realityViewOrigin = Entity()
    @State private var gameRoot = Entity()
    @State private var canStack = CanStack()
    
    @State private var allBalls: [Ball] = []
    @State private var leftControllerBall = Ball()
    @State private var rightControllerBall = Ball()

    @State private var throwSpeedTracker = ThrowSpeedTracker()
    
    @State private var spatialTrackingSession = SpatialTrackingSession()
    
    private enum Attachments {
        case inGameUI
    }
    
    var body: some View {
        GeometryReader3D { geometry in
            RealityView { content, attachments in
                initializeRealityView(content, attachments)
            } update: { update, attachments in
                updateRealityView(geometry, update, attachments)
            } attachments: {
                Attachment(id: Attachments.inGameUI) {
                    GameStateView(model: model, throwSpeedTracker: throwSpeedTracker, tryAgainHandler: {
                        setUpNewGame()
                        model.gameState = .startNewGame
                    }, toppleAllHandler: {
                        toppleAllCansAndBalls()
                    })
                }
            }
        }
        // Set the dimensions of the `RealityView` to occupy roughly 1 x 1 x 1.5 m.
        .frame(width: 1500, height: 1500).frame(depth: 2250)
        .volumeBaseplateVisibility(.hidden)
        // Render tennis balls as they enter the volume.
        .preferredWindowClippingMargins([.all], 100)
        .onChange(of: model.leftController.triggeredThrow) { _, ballThrow in
            if let ballThrow {
                throwBall(ballThrow)
            }
        }
        .onChange(of: model.rightController.triggeredThrow) { _, ballThrow in
            if let ballThrow {
                throwBall(ballThrow)
            }
        }
        .onChange(of: model.leftController.triggeredShake) { _, shake in
            if shake != nil {
                setUpNewGame()
            }
        }
        .onChange(of: model.rightController.triggeredShake) { _, shake in
            if shake != nil {
                setUpNewGame()
            }
        }
        .onChange(of: model.rightController.isTracked) { _, isTracked in
            if isTracked {
                attachBallToPredictedController(spatialController: model.rightController)
            }
        }
        .onChange(of: model.leftController.isTracked) { _, isTracked in
            if isTracked {
                attachBallToPredictedController(spatialController: model.leftController)
            }
        }
        .onDisappear() {
            model.stopTracking()
        }
        .task {
            while true {
                if Task.isCancelled { break }
                
                // While the game is running, check which cans topple at 10 Hz.
                try? await Task.sleep(nanoseconds: 1_000_000_000 / 10)
            
                if model.gameState == .gameRunning {
                    checkForToppledCans()
                }
            }
        }
        .task {
            let config = SpatialTrackingSession.Configuration(tracking: [.accessory])
            if let unavailableCapabilities = await spatialTrackingSession.run(config) {
                print("SpatialTrackingSession unavailable capabilities: \(unavailableCapabilities)")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                AppStateView(model: model, leftControllerBall: leftControllerBall, rightControllerBall: rightControllerBall)
            }
        }
    }

    private func initializeRealityView(_ content: RealityViewContent, _ attachments: RealityViewAttachments) {
        content.add(gameRoot)
        content.add(realityViewOrigin)

        let crate = Crate()
        gameRoot.addChild(crate)

        for _ in 0..<AccessoryTrackingModel.maxThrowsPerGame {
            let gameBall = Ball()
            allBalls.append(gameBall)
            gameRoot.addChild(gameBall)
        }
        
        setUpNewGame()

        if let inGameUIAttachment = attachments.entity(for: Attachments.inGameUI) {
            crate.addChild(inGameUIAttachment)
            inGameUIAttachment.position = [0.0, 0.75, 0.54]
        }
    }
    
    private func setUpNewGame() {
        for ball in allBalls {
            ball.isEnabled = false
        }
        
        canStack.removeFromParent()
        canStack = CanStack()
        gameRoot.addChild(canStack)
        
        model.totalCanCount = canStack.cans.count
    }
    
    private func toppleAllCansAndBalls() {
        for can in canStack.cans {
            can.physicsMotion = PhysicsMotionComponent(linearVelocity: SIMD3<Float>.random(in: -10...10))
        }
        for ball in allBalls {
            ball.enablePhysics(linearVelocity: SIMD3<Float>.random(in: -10...10))
        }
    }
    
    private func updateRealityView(_ geometry: GeometryProxy3D, _ update: RealityViewContent, _ attachments: RealityViewAttachments) {
        // Get the current dimensions of the `RealityView` in meters.
        let volumeSizeMetric = update.convert(geometry.frame(in: .local), from: .local, to: .scene)
        let realityViewEdges = BoundingBox(min: [volumeSizeMetric.min.x, volumeSizeMetric.min.y, -(volumeSizeMetric.max.z / 2)],
                                           max: [volumeSizeMetric.max.x, volumeSizeMetric.max.y, (volumeSizeMetric.max.z / 2)])
        
        // Position the game just above the bottom of the volume and 50 cm toward the back.
        gameRoot.position.y = realityViewEdges.min.y + 0.02
        gameRoot.position.z = -0.5
        
        // Update the controller visualization and check whether the position is appropriate for a throw.
        let (rightControllerInsideVolume, rightControllerTooClose)
            = processControllerMovement(model.rightController, ball: rightControllerBall, realityViewEdges: realityViewEdges)
        let (leftControllerInsideVolume, leftControllerTooClose)
            = processControllerMovement(model.leftController, ball: leftControllerBall, realityViewEdges: realityViewEdges)
        
        model.isControllerInsideVolume = rightControllerInsideVolume || leftControllerInsideVolume
        
        let controllerTooClose = rightControllerTooClose || leftControllerTooClose
        if model.gameState == .gameRunning && controllerTooClose {
            model.gameState = .controllersTooCloseToCanStack
        } else if model.gameState == .controllersTooCloseToCanStack && !controllerTooClose {
            // Green-light the game if neither controller is too close to the can stack.
            model.gameState = .gameRunning
        }
    }
    
    private func attachBallToPredictedController(spatialController: SpatialController) {
        guard let anchor = spatialController.anchor, case let .device(device) = anchor.accessory.source else {
            return
        }
        
        let ballEntity = anchor.accessory.inherentChirality == .left ? leftControllerBall : rightControllerBall
        guard ballEntity.parent == nil else {
            // Skip this function if the ball is already attached to an `AnchorEntity`.
            return
        }

        Task {
            // Create an `AnchorEntity` for the predicted controller and attach the tennis ball to it.
            guard let source = try? await AnchoringComponent.AccessoryAnchoringSource(device: device) else {
                return
            }
            let location = source.locationName(named: "aim")!
            
            let predictedAnchor = AnchorEntity(.accessory(from: source, location: location),
                                               trackingMode: .predicted, physicsSimulation: .none)
            predictedAnchor.addChild(ballEntity)
            gameRoot.addChild(predictedAnchor)
        }
    }
    
    private func checkForToppledCans() {
        for can in canStack.cans {
            let canRotationMatrix = can.transform.matrix.rotationMatrix

            let canYAxis: SIMD3<Float> = canRotationMatrix.columns.1
            
            // Compute the can's angle with respect to gravity and consider
            // it toppled if that angle is more than 10 degrees,
            // or if it falls out of the crate (y-coordinate below zero).
            let angleInDegrees = (1.0 - dot(canYAxis, [0, 1, 0])) * 90.0
            let toppleThresholdInDegrees: Float = 10
            
            if abs(angleInDegrees) > toppleThresholdInDegrees || can.position.y < -0.5 {
                model.setCanIsToppled(can)
            } else if abs(angleInDegrees) <= toppleThresholdInDegrees {
                model.setCanIsToppled(can, toppled: false)
            }
        }
    }
    
    /** Takes a tennis ball and:
      1. Spawns it at the location of the controller.
      2. Sets the ball's initial linear velocity to match the controller's velocity.
      3. Turns on physics for the ball, which results in a throw. */
    private func throwBall(_ ballThrow: Throw) {
        guard let anchor = ballThrow.anchor else {
            print("Can't throw ball - the anchor is missing.")
            return
        }
        let ballEntity = anchor.accessory.inherentChirality == .left ? leftControllerBall : rightControllerBall
        
        // Select a ball for this individual throw to send flying, and hide the held ball for a while.
        let thrownBall = allBalls[model.remainingThrows - 1]
        thrownBall.transform = Transform(matrix: ballEntity.transformMatrix(relativeTo: gameRoot))
        thrownBall.isEnabled = true
        ballEntity.isEnabled = false
        model.ballThrown()
        
        // Convert the anchor's velocity vector from the anchor's local coordinate space
        // to the coordinate space of the `RealityView`.
        let anchorSpace = anchor.coordinateSpace(correction: .none)
        guard let velocityInRealityView = try? anchorSpace.convert(value: Vector3DFloat(vector: anchor.velocity), to: gameRoot) else {
            print("Conversion from anchor space to RealityView space failed.")
            return
        }
        guard let angularVelocityInRealityView = try? anchorSpace.convert(value: Vector3DFloat(vector: anchor.angularVelocity), to: gameRoot) else {
            print("Conversion from anchor space to RealityView space failed.")
            return
        }
        
        // Set the initial velocity of the ball to be the controller's velocity.
        // (Plus some extra speed to make the experience more enjoyable.)
        let velocity = velocityInRealityView.vector.normalized() * ballThrow.peakSpeed * 2
        thrownBall.enablePhysics(linearVelocity: velocity, angularVelocity: angularVelocityInRealityView.vector)
        
        throwSpeedTracker.recordThrow(speed: length(velocity))
    }
    
    /** Process an updated controller:
     * Check whether it's inside the volumetric window.
     * Check whether the controller's ball needs to be visible or hidden.
     * Check whether the controller is too close to the stack of cans.
     */
    private func processControllerMovement(_ controller: SpatialController, ball: Ball, realityViewEdges: BoundingBox) -> (Bool, Bool) {
        var isInsideRealityView = false
        guard ball.parent != nil else {
            return (isInsideRealityView, false)
        }

        if let controllerAnchor = controller.anchor {
            // Check whether the controller is inside the `RealityView` and update the velocity visualization arrow.
            let aimPoint = controllerAnchor.coordinateSpace(for: .aim, correction: .rendered)
            
            if let realityViewFromAimPointTransform = try? realityViewOrigin.transform(from: aimPoint) {
                let aimPointPosition = realityViewFromAimPointTransform.matrix.columns.3.xyz
                isInsideRealityView = realityViewEdges.contains(aimPointPosition)
            }
            
            let anchorSpace = controllerAnchor.coordinateSpace(correction: .none)
            let velocityInBallCoordinates = try! anchorSpace.convert(value: Vector3DFloat(vector: controllerAnchor.velocity), to: ball)
            let velocityVector = velocityInBallCoordinates.vector
            let visualizationLength = length(velocityVector) / 3.3
            ball.velocityVisualization.transform = Transform(matrix: velocityVector.rotationMatrixAlignedOnYAxis(scaledTo: visualizationLength))
        }
        
        // Show the ball at the controller's aim point only if:
        // 1. The game is running.
        // 2. You're tracking the controller.
        // 3. No throw is in progress on this controller.
        ball.isEnabled = model.gameState == .gameRunning && controller.isTracked && controller.triggeredThrow == nil

        // For connected controllers, consider them too close to the can stack if the distance is less than 30 cm.
        let isTooCloseToCanStack = controller.isTracked &&
                                   abs(ball.position(relativeTo: gameRoot).z - canStack.position(relativeTo: gameRoot).z) < 0.3
        return (isInsideRealityView, isTooCloseToCanStack)
    }
}
