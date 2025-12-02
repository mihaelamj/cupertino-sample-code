/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A container for video playback.
*/

import RealityKit
import SwiftUI

struct VideoPlayerView: View {
    let videoModel: VideoModel

    @Environment(AppModel.self) private var appModel
    @Environment(PlayerModel.self) private var playerModel
    @Environment(\.scenePhase) private var scenePhase

    private let rootEntity = Entity()
    private let videoEntity = Entity()
    private let gestureReceiver = ModelEntity()
    private let immersiveControls = Entity()
    private let headAnchor: AnchorEntity = {
        let headAnchor = AnchorEntity(.head)
        headAnchor.anchoring.trackingMode = .once
        return headAnchor
    }()

    @State private var areTransportControlsVisible = true
    @State private var transportHideTask: Task<Void, Never>?
    @State private var isImmersiveTransitionPending = false

    var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                configureContent(content, playbackScene: appModel.playbackScene)
                scaleToFit(videoEntity, proxy: geometry, content: content)
                content.add(rootEntity)
            } update: { content in
                scaleToFit(videoEntity, proxy: geometry, content: content)
            }
            .gesture(tapGesture)
            .onDisappear {
                reset()
            }
            .onChange(of: appModel.videoModes) { _, modes in
                guard let modes, var videoPlayerComponent = videoEntity.videoPlayerComponent else {
                    return
                }
                videoEntity.applyVideoModes(modes, to: &videoPlayerComponent)
            }
            .onChange(of: playerModel.isReadyToPlay, initial: true) { _, ready in
                if ready {
                    playerModel.play()
                }
            }
            .onChange(of: playerModel.isPlaying) { _, playing in
                if playing {
                    dismissAfterDelay()
                } else {
                    transportHideTask?.cancel()
                }
            }
            .onChange(of: areTransportControlsVisible) { _, visible in
                animateTransportControls(isVisible: visible)
                if visible {
                    dismissAfterDelay()
                }
            }
            .onChange(of: scenePhase) { _, scenePhase in
                guard scenePhase == .background else { return }

                if !isImmersiveTransitionPending {
                    playerModel.stop()
                }
            }
            .loadingIndicatorSceneOverlay(appModel: appModel)
        }
    }

    // MARK: Private behavior

    private func animateTransportControls(isVisible: Bool) {
        let opacityBounds: (from: Float, to: Float) = isVisible ? (0, 1) : (1, 0)

        let fadeAnimation = FromToByAnimation<Float>(
            from: opacityBounds.from,
            to: opacityBounds.to,
            duration: 0.3,
            bindTarget: .opacity,
            repeatMode: .none
        )

        if let animationResource = try? AnimationResource.generate(with: fadeAnimation) {
            immersiveControls.playAnimation(animationResource, handoffType: .compose)
        }
    }

    private func configureContent(_ content: RealityViewContent, playbackScene: AppModel.PlaybackScene? = nil) {
        guard let playbackScene else {
            debugPrint("Unspecified playback scene — nothing to configure.")
            return
        }

        switch playbackScene {
        case .immersive:
            setupGestureReceiver(parent: rootEntity, child: gestureReceiver)
            setupImmersiveControls(parent: rootEntity, child: immersiveControls)
            fallthrough
        case .window:
            setupPlayer(content, parent: rootEntity, child: videoEntity, model: videoModel)
            subscribeToEvents(content: content, entity: videoEntity)
        }
    }

    private func dismissAfterDelay() {
        transportHideTask?.cancel()
        transportHideTask = Task {
            try? await Task.sleep(for: .seconds(3.0))

            if !Task.isCancelled {
                areTransportControlsVisible = false
                updateImmersiveControls()
            }
        }
    }

    private func handleImmersiveViewingModeChangeIfNeeded(
        previousMode: VideoPlayerComponent.ImmersiveViewingMode?,
        currentMode: VideoPlayerComponent.ImmersiveViewingMode?,
        condition: Bool = true
    ) {
        guard condition, let currentMode, currentMode != previousMode else {
            return
        }

        if let scene = AppModel.PlaybackScene(immersiveViewingMode: currentMode) {
            appModel.requestStage(.playing(scene))
        }
    }

    private func reset() {
        transportHideTask?.cancel()
        videoEntity.resetVideoPlayerComponent()
    }

    func scaleToFit(_ entity: Entity, proxy: GeometryProxy3D, content: RealityViewContent) {
        guard let videoPlayer = videoEntity.videoPlayerComponent, videoPlayer.needsScaling else {
            return
        }

        let frame = proxy.frame(in: .local)
        let frameSize = abs(content.convert(frame.size, from: .local, to: .scene))
        entity.scaleToFit(videoPlayer.playerScreenSize, within: frameSize)
    }

    private func setupGestureReceiver(parent: Entity, child: ModelEntity) {
        child.collision = CollisionComponent(shapes: [.generateBox(size: [2, 2, 0.001])], mode: .trigger)
        child.components.set(InputTargetComponent())
        child.position = [0, 1, -2]

        parent.addChild(child)
    }

    private func setupImmersiveControls(parent: Entity, child: Entity) {
        updateImmersiveControls()
        child.position = [0, 0.75, -1]
        parent.addChild(child)
    }

    private func setupPlayer(_ content: RealityViewContent, parent: Entity, child: Entity, model: VideoModel) {
        guard let videoModes = appModel.videoModes else {
            debugPrint("Unable to configure video player - missing video modes")
            return
        }
        child.makeVideoPlayerComponent(with: playerModel.player, modes: videoModes)

        if appModel.needsHeadRelativePositioning {
            child.setPosition([0, 0, -1], relativeTo: headAnchor)
            headAnchor.addChild(child)
            content.add(headAnchor)
        } else {
            parent.addChild(child)
        }
    }

    private func subscribeToEvents(content: RealityViewContent, entity: Entity) {
        _ = content.subscribe(
            to: VideoPlayerEvents.ImmersiveViewingModeWillTransition.self,
            on: entity
        ) { event in
            isImmersiveTransitionPending = true
            areTransportControlsVisible = false
            handleImmersiveViewingModeChangeIfNeeded(
                previousMode: event.previousMode,
                currentMode: event.currentMode,
                condition: (videoModel.contentType == .spatial)
            )
        }

        _ = content.subscribe(
            to: VideoPlayerEvents.ImmersiveViewingModeDidChange.self,
            on: entity
        ) { event in
            handleImmersiveViewingModeChangeIfNeeded(
                previousMode: event.previousMode,
                currentMode: event.currentMode
            )
        }

        _ = content.subscribe(
            to: VideoPlayerEvents.ImmersiveViewingModeDidTransition.self,
            on: entity
        ) { event in
            areTransportControlsVisible = true
        }

        _ = content.subscribe(
            to: VideoPlayerEvents.RenderingStatusDidChange.self,
            on: entity
        ) { [weak playerModel] event in
            playerModel?.updateVideoRenderingStatus(isVideoReadyToRender: (event.currentStatus == .ready))
        }

        _ = content.subscribe(
            to: VideoPlayerEvents.VideoComfortMitigationDidOccur.self,
            on: entity
        ) { event in
            areTransportControlsVisible = true
            updateImmersiveControls(with: event.comfortMitigation)
        }
    }

    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { _ in
                areTransportControlsVisible.toggle()
            }
    }

    private func updateImmersiveControls(with mitigation: VideoPlayerComponent.VideoComfortMitigation? = nil) {
        let controlsAttachment = ViewAttachmentComponent(rootView: ImmersiveControlsView(comfortMitigation: mitigation))
        immersiveControls.components.set(controlsAttachment)
    }
}
