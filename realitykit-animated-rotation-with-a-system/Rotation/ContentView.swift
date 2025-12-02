/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view for the app. This RealityView contains the rotating entity.
*/
import SwiftUI
import RealityKit
import SceneAssets

struct ContentView: View {
    @State var telescope: Entity? = nil
    @State var axis: RotationAxis = .xAxis
    @State var isRotating: Bool = false
    
    var body: some View {
        VStack {
            RealityView { content in
                /// Load the scene as configured in Reality Composer Pro and add it to the RealityView's content.
                if let telescopeEntity = try? await Entity(named: "Scene", in: sceneAssetsBundle) {
                    telescopeEntity.components.set(RotationComponent())
                    content.add(telescopeEntity)
                    telescope = telescopeEntity
                } else {
                    let errorText = ModelEntity(mesh: MeshResource.generateText("Telescope Not Found"),
                                           materials: [SimpleMaterial(color: .purple, isMetallic: false)])
                    errorText.components.set(RotationComponent())
                    telescope = errorText
                }
            } update: { context in
                /// Set the rotation axis of the telescope's rotation component to the selected axis.
                telescope?.components[RotationComponent.self]?.rotationAxis = axis
                /// Set the speed of the telescope's rotation component to 1.0 if the entity is rotating, 0.0 otherwise.
                telescope?.components[RotationComponent.self]?.speed = isRotating ? 1.0 : 0.0
            }
            .padding()
            
            Text("Hubble Space Telescope")
                .padding()
            Text(hubbleDescription)
                .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                ForEach(RotationAxis.allCases) { axis in
                    Toggle(isOn: Binding<Bool>(
                        get: { axis == self.axis },
                        set: { _ in self.axis = axis }
                    )) {
                        Text(axis.rawValue)
                            .foregroundStyle(axis == self.axis ? .orange : .blue)
                    }
                }
                .onChange(of: axis) { oldValue, newValue in
                    /// When the value of `axis` changes stop rotating.
                    isRotating = false
                    /// Also, animate then entity back to identity.
                    telescope?.move(to: Transform.identity,
                                    relativeTo: telescope?.parent,
                                    duration: 0.25)
                }
                Divider()
                /// Add a button that toggles the `isRotating` variable.
                Toggle(isOn: $isRotating) {
                    Text(isRotating ? "Stop Rotating" : "Rotate")
                }
                Button {
                    isRotating = false
                    telescope?.move(to: Transform.identity,
                                    relativeTo: telescope?.parent,
                                    duration: 0.25)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
        .padding()
    }
    
    // more info: https://en.wikipedia.org/wiki/Hubble_Space_Telescope
    let hubbleDescription = """
Throughout the history of science, revolutionary instruments propel our understanding with their landmark
 discoveries. The Hubble Space Telescope is a testament to that concept. Its design, technology and
 serviceability have made it one of NASA's most transformative observatories. From determining the atmospheric
 composition of planets around other stars to discovering dark energy, Hubble has changed humanity's
 understanding of the universe.
"""
}
