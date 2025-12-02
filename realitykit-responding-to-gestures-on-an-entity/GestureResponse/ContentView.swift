/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view for the app. This is where the RealityView that contains the event enabled entity is.
*/
import SwiftUI
import RealityKit
import Observation

/// Mark this as `@Observable` so that SwiftUI calls `update:` on the `RealityView` when it changes.
@Observable
public class ActiveComponent: Component {
    public var active: Bool = false
}

struct ContentView: View {
    var cube: ModelEntity

    init() {
        cube = ModelEntity(mesh: .generateBox(size: 0.1),
                               materials: [SimpleMaterial(color: .orange, isMetallic: false)])
        /// Add an input target component so the event system knows this entity should participate in event processing.
        cube.components.set(InputTargetComponent())
        /// Add a collision component to the cube entity so it gets collision tested when processing events.
        cube.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: SIMD3<Float>(0.1, 0.1, 0.1))]))
        /// Set the name there's something to display in the pop-up attachment.
        cube.name = "Groovy Cube"
        /// Add the component so the app displays the attachement.
        cube.components.set(ActiveComponent())
    }
    
    var body: some View {
        RealityView { content, attachments in
            /// Schedule adding the cube to the reality view's entity tree.
            content.add(cube)
        } update: { content, attachments in
            /// A more sophisticated entity tree would use a query to find the entities instead of having them in
            /// a property on the view.
            /// Because this sample has only one entity, use it.
            guard let component = cube.components[ActiveComponent.self] else { return }
            /// Look for the attachment entity.
            guard let attachmentEntity = attachments.entity(for: cube.id) else { return }
            /// Display the attachment if it's active; otherwise, remove it from the entity tree.
            if component.active {
                /// Add the billboard component so the attachment always faces the person.
                attachmentEntity.components.set(BillboardComponent())
                /// Add the attachment as a child of the cube.
                /// Because the subentities are a set, you can add the attachment multiple times with no ill effect.
                cube.addChild(attachmentEntity)
                /// Set the position so the attachment is visible above the entity.
                attachmentEntity.setPosition(SIMD3<Float>(0.0, 0.1, 0.0),
                                             relativeTo: cube)
            } else {
                /// When inactive, remove the attachment entity.
                cube.removeChild(attachmentEntity)
            }
        } attachments: {
            /// Create an attachment with the cube's ID.
            Attachment(id: cube.id) {
                /// Use the name of the cube in the attachment view.
                Text("\(cube.name)")
                    .padding()
                    .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 5.0))
                    /// Use the cube's ID as the tag of the view as well.
                    .tag(cube.id)
            }
        }
        /// Add the gesture to the view.
        .gesture(SpatialEventGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                /// When the gesture ends, toggle the value of the component's `active` property.
                value.entity.components[ActiveComponent.self]?.active.toggle()
            })
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
