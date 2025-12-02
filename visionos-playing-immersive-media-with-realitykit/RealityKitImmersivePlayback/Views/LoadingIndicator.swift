/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A group of views used to convey indeterminate progress.
*/

import RealityKit
import SwiftUI

// MARK: - LoadingIndicator

private struct LoadingIndicator: View {
    private static let dimension = CGFloat(80)

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .frame(width: Self.dimension, height: Self.dimension)
    }
}

// MARK: - LoadingIndicatorOverlay

private struct LoadingIndicatorOverlay: View {
    let model: PlayerModel

    var body: some View {
        withAnimation {
            VStack(alignment: .center) {
                ZStack {
                    Color.clear
                    LoadingIndicator()
                }
                .glassBackgroundEffect()
            }
            .opacity(model.isReadyToPlay ? 0 : 1)
        }
    }
}

// MARK: - LoadingIndicatorSpatialOverlay

private struct LoadingIndicatorSpatialOverlay: View {
    let model: PlayerModel

    var body: some View {
        withAnimation {
            RealityView { content in
                let child = Entity(components: ViewAttachmentComponent(rootView: LoadingIndicator()))
                child.position = [0, 1, -1]
                content.add(child)
            }
            .opacity(model.isReadyToPlay ? 0 : 1)
        }
    }
}

// MARK: - LoadingIndicatorSceneOverlay

extension View {
    func loadingIndicatorSceneOverlay(appModel: AppModel) -> some View {
        modifier(LoadingIndicatorSceneOverlayModifier(appModel: appModel, playerModel: appModel.playerModel))
    }
}

// MARK: - LoadingIndicatorSceneOverlayModifier

struct LoadingIndicatorSceneOverlayModifier: ViewModifier {
    let appModel: AppModel
    let playerModel: PlayerModel

    func body(content: Content) -> some View {
        if let playbackScene = appModel.playbackScene {
            switch playbackScene {
            case .immersive:
                content
                    .spatialOverlay {
                        LoadingIndicatorSpatialOverlay(model: playerModel)
                    }
            case .window:
                content
                    .overlay {
                        LoadingIndicatorOverlay(model: playerModel)
                    }
            }
        } else {
            content
        }
    }
}
