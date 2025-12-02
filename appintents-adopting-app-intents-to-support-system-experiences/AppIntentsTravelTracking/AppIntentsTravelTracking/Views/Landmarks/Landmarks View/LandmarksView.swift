/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI
import AppIntents

struct LandmarksView: View {
    @Environment(ModelData.self) var modelData

    var body: some View {
        GeometryReader { geometry in
            LandmarksNavigationStack(geometry: geometry)
        }
    }
}

#Preview {
    LandmarksView()
        .environment(ModelData())
}
