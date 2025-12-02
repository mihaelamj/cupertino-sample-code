/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Handle connections and inputs with Game Controller framework.
*/

import ARKit
import RealityKit
@preconcurrency import GameController

extension SculptingToolModel {
    
    // Set up button and haptic inputs for GCStylus.
    @MainActor
    func setupStylusInputs(stylus: GCStylus, hapticsModel: HapticsModel) {
        if let input = stylus.input {
            let buttonSidePrimary = input.buttons[.stylusPrimaryButton] // Primary side button
            let buttonSideSecondary = input.buttons[.stylusSecondaryButton] // Secondary side button
            buttonSidePrimary?.pressedInput.pressedDidChangeHandler = { _, _, pressed in
                self.handlePalettePress(pressed: pressed)
            }
            
            buttonSideSecondary?.pressedInput.pressedDidChangeHandler = { _, _, pressed in
                self.sculptingTool.components[SculptingToolComponent.self]?.isActive = pressed
                hapticsModel.handleSculptHaptics(pressed: pressed)
            }
        }
        if let haptics = stylus.haptics {
            hapticsModel.setupHaptics(haptics: haptics)
        }
    }
    
    // Set up button and haptic inputs for GCController.
    @MainActor
    func setupControllerInputs(controller: GCController, hapticsModel: HapticsModel) {
        let input = controller.input
        
        input.buttons[.trigger]?.pressedInput.pressedDidChangeHandler = { _, _, pressed in
            self.sculptingTool.components[SculptingToolComponent.self]?.isActive = pressed
            hapticsModel.handleSculptHaptics(pressed: pressed)
        }
        
        input.buttons[.thumbstickButton]?.pressedInput.pressedDidChangeHandler = { _, _, pressed in
            self.handlePalettePress(pressed: pressed)
        }
        
        if let haptics = controller.haptics {
            hapticsModel.setupHaptics(haptics: haptics)
        }
    }

    // Handle connections with GCControllers and GCStyluses.
    func handleGameControllerSetup(hapticsModel: HapticsModel) async {
        let controllers = GCController.controllers()
        let styluses = GCStylus.styli

        self.hapticsModel = hapticsModel

        // Iterate over all the currently connected connections with controllers and styluses.
        for controller in controllers {
            // Controllers which do not support spatial accessory tracking should not attempt to start spatial tracking.
            if controller.productCategory != GCProductCategorySpatialController {
                continue
            }
            
            try? await setupSpatialAccessory(device: controller, hapticsModel: hapticsModel)
        }
        
        for stylus in styluses {
            // Styluses which do not support spatial accessory tracking should not attempt to start spatial tracking.
            if stylus.productCategory != GCProductCategorySpatialStylus {
                continue
            }
            try? await setupSpatialAccessory(device: stylus, hapticsModel: hapticsModel)
        }

        // Listen to notifications for connections of both controllers and styluses.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: nil) {
            notification in
                if let controller = notification.object as? GCController,
                   controller.productCategory == GCProductCategorySpatialController {
                Task { @MainActor in
                    try? await self.setupSpatialAccessory(device: controller, hapticsModel: hapticsModel)
                }
            }
        }
                
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCStylusDidConnect, object: nil, queue: nil) {
            notification in
            if let stylus = notification.object as? GCStylus,
               stylus.productCategory == GCProductCategorySpatialStylus {
                Task { @MainActor in
                    try? await self.setupSpatialAccessory(device: stylus, hapticsModel: hapticsModel)
                }
            }
        }
    }
}
