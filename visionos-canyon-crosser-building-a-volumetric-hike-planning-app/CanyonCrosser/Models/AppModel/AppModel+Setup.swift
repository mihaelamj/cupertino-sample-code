/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extension on `AppModel` to set up all entities.
*/

import SwiftUI
import RealityKit
import RealityKitContent

extension AppModel {

    /// Sets up hike with trailheads and rest stops.
    func setUpHikes() {
        for hike in hikes {
            setUpTrailhead(hike: hike)
            for restStop in hike.restStops {
                if let restStopIndex = hike.restStops.firstIndex(where: { $0.name == restStop.name }) {
                    setUpRestStop(restStop: restStop, for: hike, restStopIndex: restStopIndex)
                }
            }
        }
    }

    /// Performs setup for the trailhead entity.
    /// - Parameters:
    /// - hike: The hike that the trailheads belongs to.
    func setUpTrailhead(hike: Hike) {
        // Load the trailhead posts from Reality Composer Pro.
        guard let trailheadEntity = self.grandCanyonEntity.findEntity(named: hike.trailhead.entityName) else {
            return
        }

        // Set up the presentation component.
        var trailHeadPopover = PresentationComponent(configuration: .popover(arrowEdge: .bottom), content: HikeDetailView(hike: hike))
        trailHeadPopover.isPresented = false

        // Anchor the popover to the trailhead.
        let trailheadPopoverPositioningEntity = addBillboardingPositioningEntity(
            for: trailHeadPopover,
            offset: SIMD3<Float>(0.0, 1.4, 0.0),
            relativeTo: trailheadEntity
        )
        // Create the gesture to open the popover.
        let gestureComponent = GestureComponent(SpatialTapGesture().onEnded { [weak trailheadPopoverPositioningEntity] _ in
            trailheadPopoverPositioningEntity?.components[PresentationComponent.self]?.isPresented.toggle()
        })

        // Enable tapping to open the popover.
        trailheadEntity.components.set([
            InputTargetComponent(),
            HoverEffectComponent(),
            CollisionComponent(shapes: [
                .generateBox(size: SIMD3<Float>(x: 0.3, y: 0.6, z: 0.1))
                .offsetBy(translation: SIMD3<Float>(0.0, 0.3, 0.0))
            ]),
            gestureComponent
        ])

        // Create the trailhead name attachment.
        let trailNameAttachment = ViewAttachmentComponent(
            rootView: TrailheadTitleView(
                hikeName: hike.name,
                entity: trailheadPopoverPositioningEntity
            )
        )
        // Create the anchor to position it and add it to the trailhead.
        let trailheadNamePositioningEntity = addBillboardingPositioningEntity(
            for: trailNameAttachment,
            offset: SIMD3<Float>(x: 0, y: 1.1, z: 0),
            relativeTo: trailheadEntity
        )
        trailheadNamePositioningEntity.scale = 1.0 / trailheadEntity.scale(relativeTo: nil)
    }

    /// Performs setup for a single rest stop.
    /// - Parameters:
    ///   - rest stop: The rest stop to set up.
    ///   - hike: The hike that the rest stop belongs to.
    ///   - restStopIndex: The index at which the rest stop is in the array.
    func setUpRestStop(restStop: RestStop, for hike: Hike, restStopIndex: Int) {
        // Load the rest stop entity from Reality Composer Pro. The entity is initially off.
        guard let restStopEntity = hikeEntities[hike]?.first(where: { $0.name == restStop.entityName }) else {
            return
        }
        restStopEntity.isEnabled = false

        // Set up the presentation component.
        var restStopPopover = PresentationComponent(
            configuration: .popover(arrowEdge: .bottom),
            content: RestStopDetailView(
                featuredImageName: hike.featuredImageName,
                restStop: restStop
            )
        )
        restStopPopover.isPresented = false

        // Anchor the popover to the rest stop entity.
        let restStopPopoverPositioningEntity = addBillboardingPositioningEntity(
            for: restStopPopover,
            offset: SIMD3<Float>(0.0, 0.8, 0.0),
            relativeTo: restStopEntity
        )

        // Create the gesture to open the popover.
        let gestureComponent = GestureComponent(SpatialTapGesture().onEnded { [weak restStopPopoverPositioningEntity] _ in
            restStopPopoverPositioningEntity?.components[PresentationComponent.self]?.isPresented.toggle()
        })

        // Enable tapping on the entity.
        restStopEntity.generateCollisionShapes(recursive: true)
        restStopEntity.components.set([
            InputTargetComponent(),
            HoverEffectComponent(),
            gestureComponent
        ])
    }

    /// Performs setup for the clouds.
    func setUpClouds(clippingMarginEnvironment: ClippingMarginPercentageComponent.Environment) {
        cloudsEntity.components.set(OpacityComponent())

        for child in self.cloudsEntity.children {
            if let childMesh = child.children.first {
                childMesh.components.set(ClippingMarginPercentageComponent(environment: clippingMarginEnvironment))
                childMesh.components.set(FadingCloudComponent())
            } else {
                assertionFailure("Expected a child of each cloud entity to apply the FadingCloudComponent to.")
            }

            let start = self.cloudsEntity.transform
            var end = start

            // Each cloud has two identical sibling clouds spaced exactly 1 m to its left, and 1 m to its right.
            end.translation.x = -1.0
            var cloudAnimation = FromToByAnimation(from: start, to: end, bindTarget: .transform)
            cloudAnimation.duration = 45.0
            // Return to the beginning when the animation ends. This looks seamless because
            // each cloud has a twin 1 m to its left and 1 m to its right.
            cloudAnimation.repeatMode = .repeat
            cloudAnimation.delay = 0.0
            do {
                let cloudAnimationResource = try AnimationResource.generate(with: cloudAnimation)

                cloudsAnimationController = self.cloudsEntity.playAnimation(cloudAnimationResource.repeat(duration: .infinity))
                cloudsAnimation = cloudAnimationResource
            } catch {
                print("Error generating animation resource for clouds: \(error)")
            }
        }
    }

    /// Performs setup for the birds.
    func setUpBirds() {
        birdsEntity.components.set(OpacityComponent())

        if let animation = birdsEntity.availableAnimations.first {
            birdsAnimationController = birdsEntity.playAnimation(
                animation.repeat(duration: .infinity),
                transitionDuration: 0.0,
                startsPaused: false
            )
            birdsAnimation = animation
        }
    }

    func setUpTimeOfDayEntities() {
        sunlight.components.set(LightRotationComponent(landmarkEntity: grandCanyonEntity))
        sunlight.components.set(TimeOfDayComponent())

        root.forEachDescendant(withComponent: TimeOfDayMaterialComponent.self) { entity, component in
            entity.components.set(TimeOfDayComponent())
        }
        root.forEachDescendant(withComponent: TimeOfDayLightComponent.self) { entity, component in
            entity.components.set(TimeOfDayComponent())
        }
    }

    /// Performs setup for the hiker.
    func setUpHiker() {
        // Set up gesture interaction on the hiker entity and add all custom components.
        hikerEntity.components.set([
            InputTargetComponent(),
            HoverEffectComponent(),
            HikerProgressComponent(),
            HikerDragStateComponent(),
            HikePlaybackStateComponent(),
            HikeTimingComponent(),
            GestureComponent(DragGesture(minimumDistance: 0)
                .onChanged { [weak self] event in
                    self?.hikerDragChanged(event: event)
                }
                .onEnded { [weak self] _ in
                    self?.hikerDragEnded()
                })
        ])

        // Create the positioning entity for the hiker elevation view.
        let hikerElevationPositioningEntity = addBillboardingPositioningEntity(
            for: ViewAttachmentComponent(rootView: HikerElevationView()),
            offset: SIMD3<Float>(x: 0.0, y: 10.8, z: 0.0),
            relativeTo: hikerEntity
        )
        // Apply the inverse scale of the hiker so that it doesn't inherit the hikerEntity scale.
        hikerElevationPositioningEntity.scale = 1.0 / hikerEntity.scale(relativeTo: nil)

        hikerEntity.children.forEach { child in
            child.isEnabled = false
            child.components.set(CollisionComponent(shapes: [
                .generateBox(width: 5.0, height: 8.0, depth: 5.0)
                .offsetBy(translation: SIMD3<Float>(0.0, 5.0, 0.0))
            ]))
        }
    }

    func fadeInHikerElevationView() {
        guard let elevationPositioningEntity = hikerEntity.childAt(path: hikerEntity.name + ".positioningEntity") else { return }

        Entity.animateIn(entities: [elevationPositioningEntity], duration: 0.25)
    }

    func fadeOutHikerElevationView() {
        guard let elevationPositioningEntity = hikerEntity.childAt(path: hikerEntity.name + ".positioningEntity") else { return }

        Entity.animateOut(entities: [elevationPositioningEntity], duration: 0.25)
    }

    func doAllSetup() {
        // Set the `ClippingMarginPercentageComponent` on entities that need it.
        birdsEntity.components.set(ClippingMarginPercentageComponent(environment: clippingMarginEnvironment))

        setUpBirds()
        setUpHiker()
        setUpClouds(clippingMarginEnvironment: clippingMarginEnvironment)
        setUpHikes()
        setUpTimeOfDayEntities()
    }

    /// Returns an anchor that positions a view attachment entity above the specified entity.
    /// - Parameters:
    ///   - component: The view attachment or presentation component to position.
    ///   - offset: The offset to apply to the positioning entity.
    ///   - entity: The entity to position the view attachment relative to.
    private func addBillboardingPositioningEntity(for viewComponent: Component, offset: SIMD3<Float>, relativeTo entity: Entity) -> Entity {
        let positioningEntity = Entity()
        positioningEntity.position = offset
        positioningEntity.name = entity.name + ".positioningEntity"
        positioningEntity.components.set([viewComponent, BillboardComponent()])
        entity.addChild(positioningEntity)
        return positioningEntity
    }
}
