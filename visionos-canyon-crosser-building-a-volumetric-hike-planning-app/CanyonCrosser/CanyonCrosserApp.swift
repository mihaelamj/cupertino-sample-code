/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app file.
*/

import SwiftUI
import RealityKitContent

@main
struct CanyonCrosserApp: App {
    @State private var appModel: AppModel = AppModel()
    @State private var appPhaseModel: AppPhaseModel = AppPhaseModel()

    init() {
        ClippingMarginPercentageSystem.registerSystem()
        FeatheringSystem.registerSystem()
        HikeSystem.registerSystem()
        LightRotationSystem.registerSystem()
        TimeOfDayLightSystem.registerSystem()
        TimeOfDayMaterialSystem.registerSystem()
        TimeOfDaySystem.registerSystem()
    }

    var body: some Scene {
        WindowGroup() {
            ContentView()
                .environment(appModel)
                .environment(appPhaseModel)
        }
        .defaultSize(width: 2.0 * 0.74, height: 2.0 * 0.74, depth: 2.0, in: .meters)
        .windowResizability(.contentMinSize)
        .windowStyle(.volumetric)
    }
}
