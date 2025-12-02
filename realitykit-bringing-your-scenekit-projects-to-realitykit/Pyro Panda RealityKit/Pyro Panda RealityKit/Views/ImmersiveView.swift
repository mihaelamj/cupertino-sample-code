/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An immersive view that contains the Pyro Panda game within a spatial portal.
*/
import SwiftUI
import RealityKit
import PyroPanda

@available(iOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(visionOS, introduced: 26.0)
struct ImmersiveView: View {
    @Environment(AppModel.self) internal var appModel

    var body: some View {
        PyroPandaView()
            .environment(appModel)
    }
}

fileprivate extension Entity {
    var opacity: Float? {
        get { self.components[OpacityComponent.self]?.opacity }
        set {
            if let newValue {
                self.components.set(OpacityComponent(opacity: newValue))
            } else {
                self.components.remove(OpacityComponent.self)
            }
        }
    }
}

#if os(visionOS)
#Preview {
    ImmersiveView()
        .environment(AppModel())
}
#endif
