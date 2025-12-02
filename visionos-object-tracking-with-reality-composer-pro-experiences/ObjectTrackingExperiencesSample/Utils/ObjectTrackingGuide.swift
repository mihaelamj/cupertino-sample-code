/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A guide that assists users in locating a specified target object when using Object Tracking.
*/
import RealityKit
import ARKit
import SwiftUI

// The guide initially displays a semi-transparent guide model of the object it's tracking.
// Upon detection of the object, it seamlessly animates to align itself precisely
// over the real object, creating an effect that blends the model with the actual object.

@MainActor
class ObjectTrackingGuide {
    private var content: RealityViewContent
    private var anchorEntity: Entity
    private var guideEntity: Entity
    private var guideTextEntity: Entity?
    private var targetEntity: Entity
    private var completionHandler: (() -> Void)?
    private var worldTrackingProvider: WorldTrackingProvider!
    private var objectFound = false
    private var sceneEventsSubscription: EventSubscription!
    private var headAnchor: AnchorEntity!
    private let guideOpacity: Float = 0.6
    private let moveDurationInSeconds: Float = 2.5
    private let fadeOutDurationInSeconds: Float = 2.0
    private let arSession = ARKitSession()
    
    /// Initializes an instance of an object tracking guide.
    /// - Parameters:
    ///   - content: Content of the `RealityView`.
    ///   - anchorEntity: The entity serving as the object's anchor.
    ///   - guideEntity: The entity containing the guide model.
    ///   - guideTextEntity: The optional entity with text describing the guiding process.
    ///   - targetEntity: The entity that represents the target object's pose, which the guide model moves to.
    ///   - completionHandler: A closure that runs when the guide aligns with the real object.
    init(content: RealityViewContent, anchorEntity: Entity, guideEntity: Entity,
         guideTextEntity: Entity?, targetEntity: Entity, completionHandler: (() -> Void)? = nil) async {
        self.content = content
        self.anchorEntity = anchorEntity
        self.guideEntity = guideEntity
        self.guideTextEntity = guideTextEntity
        self.targetEntity = targetEntity
        self.completionHandler = completionHandler
    }
    
    /// Shows the guide to the user.
    func show() async {
        await runSpatialTrackingSession()
        await runWorldTrackingSession()
        addGuideEntityToHeadAnchor()
        observeObjectDetection()
    }
    
    private func runSpatialTrackingSession() async {
        let trackingSession = SpatialTrackingSession()
        let config = SpatialTrackingSession.Configuration(tracking: [.object, .world])
        if let unavailable = await trackingSession.run(config) {
            guard !unavailable.anchor.contains(.object) else { return }
            fatalError("Object tracking isn't available.")
        }
    }

    private func runWorldTrackingSession() async {
        self.worldTrackingProvider = WorldTrackingProvider()
        do {
            try await arSession.run([worldTrackingProvider])
        } catch let error {
            AppLogger.logError("Error while running world tracking session: \(error.localizedDescription)")
        }
    }
    
    private func addGuideEntityToHeadAnchor() {
        self.headAnchor = AnchorEntity(.head)
        headAnchor.anchoring.physicsSimulation = .none
        content.add(headAnchor)
        guideEntity.components.set(OpacityComponent(opacity: guideOpacity))
        guideEntity.position = [0, -0.15, -0.5]
        headAnchor.addChild(guideEntity)
        if let guideTextEntity {
            guideTextEntity.position = [0, -0.05, -0.5]
            headAnchor.addChild(guideTextEntity)
        }
    }
    
    private func observeObjectDetection() {
        self.sceneEventsSubscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            guard let self else { return }
            if anchorEntity.isAnchored, !objectFound {
                objectFound = true
                moveGuideToTargetEntity()
            }
        }
    }
    
    private func moveGuideToTargetEntity() {
        guideTextEntity?.removeFromParent()
        reparentGuideFromHeadAnchorToRoot()
        playMoveAnimation(from: guideEntity, to: targetEntity)
    }
    
    private func reparentGuideFromHeadAnchorToRoot() {
        let previousTransformMatrix = guideEntity.transformMatrix(relativeTo: nil)
        guideEntity.removeFromParent()
        content.add(guideEntity)
        guard let deviceAnchor = worldTrackingProvider?.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
        let deviceTransform = deviceAnchor.originFromAnchorTransform
        guideEntity.setTransformMatrix(deviceTransform * previousTransformMatrix, relativeTo: nil)
    }
    
    private func playMoveAnimation(from sourceEntity: Entity, to targetEntity: Entity) {
        let transformMatrix = targetEntity.transformMatrix(relativeTo: nil)
        let targetTransform = Transform(matrix: transformMatrix)
        let moveAction = FromToByAction(to: targetTransform, timing: .easeInOut)
        var fadeOutComponent = FadeOutComponent(duration: fadeOutDurationInSeconds, completionHandler: { [weak self] in
            self?.completionHandler?()
        })
        do {
            let animateTransform = try AnimationResource.makeActionAnimation(for: moveAction,
                                                                             duration: TimeInterval(moveDurationInSeconds),
                                                                             bindTarget: .transform)
            sourceEntity.playAnimation(animateTransform)
            fadeOutComponent.isFading = true
            guideEntity.components.set(fadeOutComponent)
        } catch {
            AppLogger.logError("Error while playing guide's move animation: \(error.localizedDescription)")
        }
    }
}
