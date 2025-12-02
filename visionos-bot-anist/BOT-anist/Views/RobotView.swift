/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the robot.
*/

import SwiftUI
import RealityKit
import Spatial

/// A view that displays the robot.
struct RobotView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var realityView: some View {
#if os(visionOS)
            ResizableRealityView()
#else
            RealityView { content in
                appState.creationRoot.scale = SIMD3<Float>(repeating: 0.027)
                appState.creationRoot.position = SIMD3<Float>(x: -0, y: -0.022, z: -0.05)
                content.add(appState.creationRoot)
                content.add(appState.robotCamera)
            }
#endif
    }

    var robotView: some View {
        realityView
            .simultaneousGesture(DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    guard appState.phase == .playing else { return }
                    handleDrag(value)
                }
                .onEnded { value in
                    appState.isRotating = false
                })
    }

    var body: some View {
#if os(visionOS)
        VStack {
            StartPlantingButtonView()
            robotView
        }
#else
        ZStack {
            robotView

            VStack {
                StartPlantingButtonView()
                Spacer()
            }
        }
#endif
    }

    /// Rotates the robot about the y-axis when a drag gesture targeting the robot occurs.
    func handleDrag(_ value: EntityTargetValue<DragGesture.Value>) {
        let entity = appState.creationRoot
        
        if !appState.isRotating {
            appState.isRotating = true
            appState.robotCreationOrientation = Rotation3D(entity.orientation(relativeTo: nil))
        }
        let yRotation = value.gestureValue.translation.width / 100
        
        let rotationAngle = Angle2D(radians: yRotation)
        let rotation = Rotation3D(angle: rotationAngle, axis: RotationAxis3D.y)
        
        let startOrientation = appState.robotCreationOrientation
        let newOrientation = startOrientation.rotated(by: rotation)
        entity.setOrientation(.init(newOrientation), relativeTo: nil)
    }
}

#if os(visionOS)
struct ResizableRealityView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        GeometryReader3D { proxy in
            RealityView { content in
                content.add(appState.creationRoot)
                content.add(appState.robotCamera)

                let viewBounds = content.convert(proxy.frame(in: .local), from: .local, to: .scene)
                adjustRobotToFillCenterOfView(viewBounds: viewBounds)
            } update: { content in
                let viewBounds = content.convert(proxy.frame(in: .local), from: .local, to: .scene)
                adjustRobotToFillCenterOfView(viewBounds: viewBounds)
            }
        }
    }

    func adjustRobotToFillCenterOfView(viewBounds: BoundingBox) {
        let robotVisualBounds = appState.creationRoot.visualBounds(relativeTo: nil)

        appState.creationRoot.position = SIMD3<Float>.zero

        // Adjust the model's position on the y-axis to align with the center of the view bounds.
        appState.creationRoot.position.y -= appState.creationRoot.visualBounds(relativeTo: nil).extents.y / 2

        // Adjust the robot to be positioned against the window, rather than in the center of the z-axis.
        appState.creationRoot.position.z -= viewBounds.max.z / 2
        appState.creationRoot.position.z += appState.creationRoot.visualBounds(relativeTo: nil).extents.z

        /// The base size of the model when the scale is 1.
        let baseExtents = robotVisualBounds.extents / appState.creationRoot.scale

        /// The scale required for the model to fit the bounds of 80% of the volumetric window.
        let scaleToFitHeight = Float(viewBounds.extents.y * 0.8) / baseExtents.y
        let scaleToFitWidth = Float(viewBounds.extents.x * 0.8) / baseExtents.x

        // Apply the scale to the model to fill the full size of the window.
        appState.creationRoot.scale = SIMD3<Float>(repeating: min(scaleToFitWidth, scaleToFitHeight))
    }
}
#endif

#Preview(traits: .sampleAppState) {
    RobotView()
}

struct StartPlantingButtonView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) internal var openWindow

    var body: some View {
        HStack {
            Spacer()
            if appState.phase == .playing {
                Button(action: {
                    appState.phase = .exploration
                    Task { @MainActor in
                        appState.prepareForExploration()
#if os(visionOS)
                        openWindow(id: "RobotExploration")
#endif
                    }
                }) {
                    Text("Start Planting", comment: "A label for the button that starts the gameplay.")
#if os (macOS)
                        .foregroundStyle(.black)
#endif
                }
                .padding()
            }
        }
        .padding([.trailing, .top])
    }
}
