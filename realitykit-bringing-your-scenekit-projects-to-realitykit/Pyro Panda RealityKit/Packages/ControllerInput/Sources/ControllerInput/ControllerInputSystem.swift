/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that passes controller inputs to the receiving entities.
*/

import GameController
import RealityKit
import SwiftUI
import HapticUtility

/// A system that continuously records the controller's current state.
public struct ControllerInputSystem: System, Sendable {
    @MainActor static var jumpPressed = false
    @MainActor static var circlePressed = false
    nonisolated(unsafe) static var controller: GCController?

    public init(scene: RealityKit.Scene) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.GCControllerDidConnect,
            object: nil, queue: nil,
            using: didConnectController)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.GCControllerDidDisconnect,
            object: nil, queue: nil,
            using: didDisconnectController)
        GCController.startWirelessControllerDiscovery()
    }

    func didConnectController(_ notification: Notification) {
        Self.controller = notification.object as? GCController
        if let controller = Self.controller {
            print("◦ connected")

            if let controller = controller.extendedGamepad {
                controller.buttonX.valueChangedHandler = { _, _, isPressed in
                    Task { @MainActor in
                        ControllerInputSystem.circleButtonChanged(isPressed)
                    }
                }
            } else if let controller = controller.microGamepad {
                controller.buttonX.valueChangedHandler = { _, _, isPressed in
                    Task { @MainActor in
                        ControllerInputSystem.circleButtonChanged(isPressed)
                    }
                }
            }

            // Register the haptic utility.
            HapticUtility.initHapticsFor(controller: controller)
        }
    }

    func didDisconnectController(_ notification: Notification) {
        print("◦ disconnected")
        // Unregister the haptic utility.
        if let controller = notification.object as? GCController {
            HapticUtility.deinitHapticsFor(controller: controller)
        }

        Self.controller = nil
    }

    @MainActor static func jumpButtonChanged(_ isPressed: Bool) {
        if isPressed {
            ControllerInputSystem.jumpPressed = true
        }
    }

    @MainActor static func circleButtonChanged(_ isPressed: Bool) {
        if isPressed {
            ControllerInputSystem.circlePressed = true
        }
    }

    mutating public func update(context: SceneUpdateContext) {
        guard let controller = GCController.current
        else { return }
        let cameraEntities = context.entities(
            matching: EntityQuery(where: .has(ControllerInputReceiver.self)),
            updatingSystemWhen: .rendering)
        var entitiesEmpty = true

        for entity in cameraEntities {
            guard var inputReceiverComponent = entity.components[ControllerInputReceiver.self]
            else { continue }
            entitiesEmpty = false

            // An extended game controller.
            if let gamepad = controller.extendedGamepad {
                inputReceiverComponent.leftJoystick = [
                    gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value]
                inputReceiverComponent.rightJoystick = [
                    gamepad.rightThumbstick.xAxis.value, gamepad.rightThumbstick.yAxis.value]

                if gamepad.buttonA.isPressed != inputReceiverComponent.jumpPressed {
                    inputReceiverComponent.jumpPressed = gamepad.buttonA.isPressed
                }
                if Self.circlePressed {
                    inputReceiverComponent.attackReady = true
                }
            } else if let gamepad = controller.microGamepad {
                // A Siri remote.
                inputReceiverComponent.leftJoystick = [
                    gamepad.dpad.xAxis.value, gamepad.dpad.yAxis.value]

                if gamepad.buttonA.isPressed != inputReceiverComponent.jumpPressed {
                    inputReceiverComponent.jumpPressed = gamepad.buttonA.isPressed
                }
                if Self.circlePressed {
                    inputReceiverComponent.attackReady = true
                }
            }

            inputReceiverComponent.update(for: entity)
            entity.components.set(inputReceiverComponent)
        }

        if !entitiesEmpty {
            Self.jumpPressed = false
            Self.circlePressed = false
        }
    }
}
