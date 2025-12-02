# Responding to gestures on an entity

Respond to gestures performed on RealityKit entities using input target and collision components.

## Overview

[`RealityView`](https://developer.apple.com/documentation/RealityKit/RealityView) receives gestures from SwiftUI.
Add an [`InputTargetComponent`](https://developer.apple.com/documentation/RealityKit/InputTargetComponent) and a [`CollisionComponent`](https://developer.apple.com/documentation/RealityKit/CollisionComponent) to entities to receive gestures.
The input target component marks entity as participating in the event system.
The system uses the collision component to test if the gaze vector intersects the entity.
With both components attached entities receive events.

## Attaching components to an entity to process events

The sample defines the `ActiveComponent`.
The component keeps track of the `active` state of the entity.

```
public class ActiveComponent: Component {
    public var active: Bool = false
}
```

This sample has one entity, a cube that is 0.1 units in each direction.
The sample creates the entity then adds the three components.

```swift
var cube = ModelEntity(mesh: .generateBox(size: 0.1),
                       materials: [SimpleMaterial(color: .orange, isMetallic: false)])

cube.components.set(InputTargetComponent())
cube.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: SIMD3<Float>(0.1, 0.1, 0.1))]))
cube.components.set(ActiveComponent())
```

The sample has a [`SpatialEventGesture`](https://developer.apple.com/documentation/swiftui/SpatialEventGesture) attached to the RealityView.
As the person interacting with the application gazes around and pinches the system will use the input target component and the collision component to determine intent.
The system considers all entities in the scene because the sample calls [targetedToAnyEntity](https://developer.apple.com/documentation/swiftui/gesture/targetedtoanyentity()).
When the person pinches on the cube the system invokes the gesture's `onEnded` block, which toggles the `active` flag.

```
.gesture(SpatialEventGesture()
    .targetedToAnyEntity()
    .onEnded { value in
        value.entity.components[ActiveComponent.self]?.active.toggle()
    })
```

The attachment is created in the `attachments:` block.

```swift
attachments: {
    Attachment(id: cube.id) {
        Text("\(cube.name)")
            .padding()
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 5.0))
            .tag(cube.id)
    }
}
```

The attachment's `id` is set to the ID of the `cube` so that it's easy to find in the reality view's `update:` block.
In the `update:` block the sample finds the `ActiveComponent` from the cube and then finds the attachment using the ID of the cube.
If the active value is `true` the code adds a [`BillboardComponent`](https://developer.apple.com/documentation/swiftui/BillboardComponent) to the attachment.
The system ensures entities with a BillboardComponent always face the person.
The attachment entity is added as a child of the cube and positioned slightly above it.

```swift
update: { content, attachments in
    guard let component = cube.components[ActiveComponent.self] else { return }
    guard let attachmentEntity = attachments.entity(for: cube.id) else { return }
    if component.active {
        attachmentEntity.components.set(BillboardComponent())
        cube.addChild(attachmentEntity)
        attachmentEntity.setPosition(SIMD3<Float>(0.0, 0.1, 0.0),
                                     relativeTo: cube)
    } else {
        cube.removeChild(attachmentEntity)
    }
}
```
