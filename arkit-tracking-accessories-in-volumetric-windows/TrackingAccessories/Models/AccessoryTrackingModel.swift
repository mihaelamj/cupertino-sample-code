/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The accessory-tracking model.
*/

import ARKit
import GameController

/// A model that holds all accessory-tracking states.
@Observable
@MainActor
final class AccessoryTrackingModel {
    enum GameState {
        case noGameStartedYet
        case startNewGame
        case gameRunning
        case controllersTooCloseToCanStack
        case gameWon
        case gameLost
    }
    
    enum State {
        case startingUp
        case accessoryTrackingNotAuthorized
        case accessoryTrackingNotSupported
        case noControllerConnected
        case arkitSessionError
        case allControllersOutOfBounds
        case noUsableController
        case inGame
    }

    private var toppledCans: [Can] = []
    private let arkitSession = ARKitSession()

    let leftController = SpatialController()
    let rightController = SpatialController()
    static let maxThrowsPerGame = 10
    var totalCanCount: Int? = nil
    var state: State = .startingUp
    
    var gameState: GameState = .noGameStartedYet {
        didSet {
            if gameState == .startNewGame {
                remainingThrows = AccessoryTrackingModel.maxThrowsPerGame
                toppledCans.removeAll()
                gameState = .gameRunning
            }
        }
    }
    
    var toppledCanCount: Int {
        toppledCans.count
    }
    
    var remainingThrows: Int = maxThrowsPerGame {
        didSet {
            if remainingThrows <= 0 && gameState == .gameRunning {
                gameState = .gameLost
            }
        }
    }
    
    var isControllerInsideVolume = false {
        didSet {
            if !isControllerInsideVolume {
                if state == .inGame {
                    state = .allControllersOutOfBounds
                }
            } else {
                state = .inGame
            }
        }
    }
    
    func ballThrown() {
        remainingThrows -= 1
    }
    
    init() {
        if !AccessoryTrackingProvider.isSupported {
            state = .accessoryTrackingNotSupported
            return
        }
        
        // Listen for connected and disconnected controllers.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidConnect,
                                               object: nil,
                                               queue: nil) { notification in
            if let controller = notification.object as? GCController {
                guard controller.productCategory == GCProductCategorySpatialController else {
                    return
                }
                
                Task { @MainActor in
                    if self.state != .inGame {
                        self.state = .startingUp
                    }
                    // Start tracking the newly connected spatial controller.
                    self.trackAllConnectedSpatialControllers()
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidDisconnect,
                                               object: nil,
                                               queue: nil) { notification in
            if let controller = notification.object as? GCController {
                if controller.productCategory == GCProductCategorySpatialController {
                    Task { @MainActor in
                        // Rerun accessory tracking for any spatial controllers still connected.
                        self.trackAllConnectedSpatialControllers()
                    }
                }
            }
        }

        // Start tracking any spatial controllers that are already connected.
        trackAllConnectedSpatialControllers()
        
        Task {
            await monitorARKitSessionEvents()
        }
    }
    
    func setCanIsToppled(_ can: Can, toppled: Bool = true) {
        if toppled && !toppledCans.contains(can) {
            toppledCans.append(can)
        } else if !toppled && toppledCans.contains(can) {
            // Collisions with other cans and tennis balls can
            // cause toppled cans to become upright again.
            toppledCans.removeAll(where: { $0 == can })
        }
        
        if let totalCanCount, toppledCans.count == totalCanCount {
            gameState = .gameWon
        }
    }
    
    func stopTracking() {
        arkitSession.stop()
    }
    
    private func controller(for anchor: AccessoryAnchor) -> SpatialController {
        anchor.accessory.inherentChirality == .left ? leftController : rightController
    }
    
    /** Monitor the speed of a controller. Trigger a "throw action" of
     the held tennis ball if the speed drops sufficiently below
     the controller's peak speed. */
    private func actOnThrow(for controller: SpatialController) {
        guard let anchor = controller.anchor else { return }
    
        let controllerSpeed = length(anchor.velocity)
        controller.pendingThrow.peakSpeed = max(controller.pendingThrow.peakSpeed, controllerSpeed)

        if controller.pendingThrow.peakSpeed > 1.2 &&
            controllerSpeed < controller.pendingThrow.peakSpeed - 0.6 {
            // Trigger a throw if:
            // The controller's peak speed is more than 1.2 m/s.
            // The controller's speed drops more than 0.6 m/s below the peak.
            if controller.triggeredThrow == nil {
                controller.pendingThrow.anchor = anchor
                
                controller.triggeredThrow = controller.pendingThrow
                controller.pendingThrow = Throw()
                
                Task {
                    // Allow the next throw after 1 second.
                    try? await Task.sleep(for: .milliseconds(1000))
                    controller.triggeredThrow = nil
                }
            }
        }
    }
    
    /** Monitor clockwise and counterclockwise rotations of a controller
     on the z-axis. After six oscillations, trigger a "shake action" to
     reset the game. */
    private func actOnShake(for controller: SpatialController) {
        guard let anchor = controller.anchor else { return }
        
        let controllerZAngularVelocity = anchor.angularVelocity[2]
        controller.pendingShake.peakAngularVelocity = max(controller.pendingShake.peakAngularVelocity, controllerZAngularVelocity)
        
        let halfPi: Float = .pi / 2

        if controllerZAngularVelocity < controller.pendingShake.peakAngularVelocity - halfPi &&
            abs(anchor.angularVelocity[0]) < halfPi && abs(anchor.angularVelocity[1]) < halfPi {
            // Detect a controller oscillation on the z-axis if:
            // The controller's angular velocity on the z-axis drops more than 90 deg/s below the peak angular velocity.
            // The controller's angular velocity on the other axes is less than 90 deg/s.
            let controllerPosition: SIMD3<Float> = anchor.originFromAnchorTransform.columns.3.xyz
            
            // Reset the shake if the user moves too much.
            if let shakePrevPos = controller.pendingShake.initialPosition {
                guard length(controllerPosition - shakePrevPos) < 0.2 else {
                    controller.pendingShake = Shake()
                    return
                }
            }
            
            if controllerZAngularVelocity < -halfPi {
                if controller.pendingShake.currentDirection == .counterClockwise {
                    controller.pendingShake.oscillationCount += 1
                }
                controller.pendingShake.currentDirection = .clockwise
            } else if controllerZAngularVelocity > halfPi {
                if controller.pendingShake.currentDirection == .clockwise {
                    controller.pendingShake.oscillationCount += 1
                }
                controller.pendingShake.currentDirection = .counterClockwise
            }
            
            if controller.pendingShake.oscillationCount == 1 {
                controller.pendingShake.initialPosition = controllerPosition
            }

            if controller.triggeredShake == nil && controller.pendingShake.oscillationCount >= 6 {
                // Trigger a shake if the user oscillates the controller on the z-axis six times.
                controller.triggeredShake = controller.pendingShake
                controller.pendingShake = Shake()
                
                gameState = .startNewGame
                
                Task {
                    // Reset the triggered shake after 0.5 seconds.
                    try? await Task.sleep(for: .milliseconds(500))
                    controller.triggeredShake = nil
                }
            }
        }
    }

    /** Tracks all connected spatial controllers by:
     1. Looping over all available controllers.
     2. Creating `Accessories` for all spatial controllers.
     3. Running an `AccessoryTrackingProvider` with these accessories on an `ARKitSession.`
     4. Listening for and processing the updated `AccessoryAnchor` on the provider's `.anchorUpdates` sequence. */
    private func trackAllConnectedSpatialControllers() {
        Task {
            guard state != .accessoryTrackingNotAuthorized && state != .accessoryTrackingNotSupported else {
                print("Can't run ARKit session: \(state)")
                return
            }
            
            var accessories: [Accessory] = []
            for spatialController in GCController.spatialControllers() {
                do {
                    let accessory = try await Accessory(device: spatialController)
                    accessories.append(accessory)
                } catch {
                    print("Error during accessory initialization: \(error)")
                }
            }
            
            guard !accessories.isEmpty else {
                state = .noControllerConnected
                arkitSession.stop()
                return
            }

            let accessoryTracking = AccessoryTrackingProvider(accessories: accessories)
            
            do {
                try await arkitSession.run([accessoryTracking])
                state = .inGame
                gameState = .startNewGame
            } catch {
                // No need to handle the error here; the app is already monitoring the
                // session for errors in `monitorSessionEvents()`.
                return
            }
            
            for await update in accessoryTracking.anchorUpdates {
                process(update)
            }
        }
    }
    
    /// Processes updated anchors. Most notably, check whether the user initiates a throw or shake action.
    private func process(_ update: AnchorUpdate<AccessoryAnchor>) {
        let controller = update.anchor.accessory.inherentChirality == .left ? leftController : rightController
        
        switch update.event {
        case .added, .updated:
            // Process added/updated accessory anchors only if you're tracking the position and orientation of the controller.
            guard update.anchor.trackingState == .positionOrientationTracked else {
                controller.anchor = nil
                
                if !leftController.isTracked && !rightController.isTracked {
                    state = .noUsableController
                }
                return
            }
            controller.anchor = update.anchor
            
            if gameState == .gameRunning {
                actOnThrow(for: controller)
            }
            
            actOnShake(for: controller)
        case .removed:
            controller.anchor = nil
            return
        }
    }
    
    private func monitorARKitSessionEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(_, let newState, let error):
                if newState == .stopped {
                    if let error {
                        print("An error occurred: \(error)")
                        state = .arkitSessionError
                    }
                }
            case .authorizationChanged(let type, let authorizationStatus):
                if type == .accessoryTracking {
                    if authorizationStatus == .denied {
                        state = .accessoryTrackingNotAuthorized
                    } else if authorizationStatus == .allowed {
                        state = .startingUp
                        // Start tracking all connected spatial controllers as soon
                        // as the user grants accessory-tracking authorization.
                        trackAllConnectedSpatialControllers()
                    }
                }
            default:
                break
            }
        }
    }
}
