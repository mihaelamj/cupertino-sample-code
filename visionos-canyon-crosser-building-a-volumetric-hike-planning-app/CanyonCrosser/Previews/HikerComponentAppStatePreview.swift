/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Preview modifier to set up hike state and information for Previews.
*/

import SwiftUI

struct HikerComponentAppModelData: PreviewModifier {
    // Setup the `appModel.hikerEntity` with the needed components for the `AppModel` to function.
    static func makeSharedContext() async throws -> AppModel {
        let appModel = AppModel()

        appModel.hikerEntity.components.set([
            HikerProgressComponent(),
            HikerDragStateComponent(),
            HikePlaybackStateComponent(),
            HikeTimingComponent()
        ])

        appModel.selectedHike = MockData.brightAngel

        // Replicate enough of the `HikeSystem` so that SwiftUI Previews can display the UI.
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 500_000)

                if let animation = appModel.hikerProgressComponent.animation {
                    appModel.hikerProgressComponent.hikeProgress = animation.toValue
                } else if !appModel.hikePlaybackStateComponent.isPaused {
                    appModel.hikerProgressComponent.hikeProgress += 0.001

                    if appModel.hikerProgressComponent.hikeProgress > 1 {
                        appModel.hikerProgressComponent.hikeProgress = 1
                        appModel.hikePlaybackStateComponent.isPaused = true
                    }
                }
            }
        }

        return appModel
    }

    func body(content: Content, context: AppModel) -> some View {
        // Inject the object into the view to preview.
        content
            .environment(context)
    }
}
