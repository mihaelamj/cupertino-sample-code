/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows the name of the trailhead.
*/

import SwiftUI
import RealityKit

struct TrailheadTitleView: View {
    let hikeName: String
    let entity: Entity

    var shouldBreakthrough: Bool {
        entity.observable.components[PresentationComponent.self]?.isPresented ?? false
    }

    var body: some View {
        Text(hikeName)
            .font(.title2)
            .padding()
            .padding(.horizontal)
            .glassBackgroundEffect()
            .onTapGesture {
                entity.components[PresentationComponent.self]?.isPresented.toggle()
            }
            .breakthroughEffect(shouldBreakthrough ? .subtle : .none)
    }
}
