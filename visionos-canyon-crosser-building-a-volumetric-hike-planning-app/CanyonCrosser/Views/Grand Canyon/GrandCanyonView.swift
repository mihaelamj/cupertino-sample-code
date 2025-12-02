/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view for the app, the Grand Canyon.
*/

import SwiftUI
import RealityKit
import Combine
import RealityKitContent

struct GrandCanyonView: View, Animatable {
    @Environment(AppModel.self) var appModel
    @Environment(\.physicalMetrics) var physicalMetrics
    @Environment(\.surfaceSnappingInfo) var surfaceSnappingInfo
    @Environment(\.windowClippingMargins) var windowClippingMargins

    /// The size of the volume in points.
    @State var volumeSize: Rect3D = .zero
    /// The size of the volume in meters.
    @State private var volumeInMeters = BoundingBox(min: .zero, max: .zero)
    
    /// The anchoring and alignment of the ornament.
    private var ornamentPlacement: (sceneAnchor: UnitPoint3D, contentAlignment: Alignment3D) {
        var (sceneAnchor, contentAlignment): (UnitPoint3D, Alignment3D) = (.center, .bottom)
        if appModel.debugSettings.controlsMovesToFrontWhenSnapped,
           surfaceSnappingInfo.isSnapped {
            sceneAnchor = .bottomFront
            contentAlignment = .bottom
        }

        if volumeSize.size.width > 1400 {
            sceneAnchor = .center
            contentAlignment = .bottom
        } else {
            sceneAnchor = .back
            contentAlignment = .center
        }

        return (sceneAnchor, contentAlignment)
    }
    
    /// The initial progress of the hiker when a drag event starts.
    @State var initialHikeProgress: Float? = nil
    
    /// The requested edge insets, these are modified after the volume is sized by the system to be 20 percent
    /// of the width and depth of the actual volume.
    private var requestedEdgeInsets: EdgeInsets3D {
        let leadingTrailingDelta = self.volumeSize.size.width * CGFloat(appModel.extendedBoundsMultiplier)
        let frontBackDelta = self.volumeSize.size.depth * CGFloat(appModel.extendedBoundsMultiplier)
        
        return EdgeInsets3D(
            top: 0.0,
            leading: leadingTrailingDelta,
            bottom: 0.0,
            trailing: leadingTrailingDelta,
            front: frontBackDelta,
            back: frontBackDelta)
    }
    
    var body: some View {
        RealityView { content in
            // Make sure the app starts with no selected hike.
            appModel.selectedHike = nil

            // Update the sun to mimic the default start time.
            setDefaultSunlight()

            // Add the root entity to the content.
            content.add(appModel.root)
        } update: { content in
            // Update the clipping and scaling of the content.
            updateMarginClippingEnvironment(in: content)
            positionAndScale(with: content)
            
            // When a hike is selected, update the trail, hiker, and sunlight.
            if let selectedHike = appModel.selectedHike {
                updateTrailAndHiker(selectedHike: selectedHike)
                // Set the sunlight rotation depending on the progress.
                setSunlight(
                    for: calculateTimeOfDay(from: appModel.hikerProgressComponent.hikeProgress),
                    shouldAnimateChange: appModel.shouldAnimateSunlightChange
                )
            }
        }
        .onChange(of: appModel.selectedHike) { _, newValue in
            if newValue == nil {
                // If there is no selected hike, revert to the default sun.
                setDefaultSunlight()
            }
        }
        .preferredWindowClippingMargins([.front, .back, .leading, .trailing], self.requestedEdgeInsets)
        .onChange(of: windowClippingMargins) {
            appModel.clippingMarginEnvironment.clippingMargins = physicalMetrics.convert(edges: windowClippingMargins, to: .meters)
        }
        .onChange(of: appModel.hikePlaybackStateComponent.isPaused) { newValue, oldValue in
            // When the hiker was paused and is now moving, fade out the clouds.
            if newValue && !oldValue {
                appModel.fadeOutClouds()
            }
            
            // When the hiker was moving and is now paused, fade in the clouds.
            if !newValue && oldValue {
                appModel.fadeInClouds()
            }
        }
        .onGeometryChange3D(for: Rect3D.self) { proxy in
            proxy.frame(in: .local)
        } action: { frame in
            volumeSize = frame
            volumeInMeters = physicalMetrics.convertToMeters(bounds: frame)
        }
        
        // Configuration panel ornament.
        .ornament(
            visibility: appModel.debugSettings.showOrnament ? .visible : .hidden,
            attachmentAnchor: .scene(.leadingFront),
            contentAlignment: .trailing
        ) {
            ConfigurationOptions()
                .frame(width: 600, height: 900)
                .rotation3DEffect(.degrees(20), axis: .y)
        }

        // The toolbar ornament.
        .ornament(
            attachmentAnchor: .scene(appModel.debugSettings.ornamentSceneAnchorOverride ?? ornamentPlacement.sceneAnchor),
            contentAlignment: appModel.debugSettings.ornamentContentAlignmentOverride ?? ornamentPlacement.contentAlignment
        ) {
            if let selectedHike = appModel.selectedHike {
                HikeControls(
                    volumeSize: volumeSize.size,
                    hike: selectedHike
                )
            }
        }
        // The ornament to go back to the carousel view.
        .ornament(
            attachmentAnchor: .scene(.bottomLeadingFront),
            contentAlignment: .bottomLeading
        ) {
            BackButtonView()
        }
    }
}
