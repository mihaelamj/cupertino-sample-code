/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows the items the player collects in the game.
*/

import SwiftUI
import RealityKit
import PyroPanda

struct CollectedItemsView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        if appModel.displayOverlaysVisible {
            ZStack {
                VStack {
                    HStack(alignment: .center, spacing: 20) {
                        statusIcon(solidImageName: "MaxIcon", size: CGSize(width: 80, height: 80))
                        statusIcon(solidImageName: "collectableBIG_full",
                                   outlinedImageName: "collectableBIG_empty",
                                   size: CGSize(width: 70, height: 70),
                                   isSolid: appModel.collectedCoin)
                        statusIcon(solidImageName: "key_full",
                                   outlinedImageName: "key_empty",
                                   size: CGSize(width: 70, height: 70),
                                   isSolid: appModel.collectedKey)
                        #if !os(visionOS)
                        Spacer()
                        #endif
                    }
                    #if !os(visionOS)
                    Spacer()
                    #endif
                }
                .padding()
            }
        }
    }

    fileprivate func statusIcon(solidImageName: String, outlinedImageName: String? = nil, size: CGSize, isSolid: Bool = true) -> some View {
        Image(isSolid ? solidImageName : outlinedImageName ?? solidImageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
    }
}

#Preview {
    CollectedItemsView()
        .environment(AppModel())
}
