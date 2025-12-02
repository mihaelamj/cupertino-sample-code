/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view containing the ornaments of the RealityView.
*/

import RealityKit
import SwiftUI

struct OrnamentsView: View {
    @Environment(AppModel.self) private var appModel
    let imageCount: Int

    var body: some View {
        VStack {
            HStack {
                Button {
                    appModel.imageIndex = (appModel.imageIndex - 1 + imageCount) % appModel.imageURLs.count
                } label: {
                    Image(systemName: "arrow.left.circle")
                }
                Button {
                    appModel.imageIndex = (appModel.imageIndex + 1) % appModel.imageURLs.count
                } label: {
                    Image(systemName: "arrow.right.circle")
                }
                Button {
                    guard var ipc = appModel.contentEntity.components[ImagePresentationComponent.self] else {
                        print("Unable to find ImagePresentationComponent.")
                        return
                    }
                    switch ipc.viewingMode {
                    case .mono:
                        switch appModel.spatial3DImageState {
                        case .generated:
                            ipc.desiredViewingMode = .spatial3D
                            appModel.contentEntity.components.set(ipc)
                        case .notGenerated:
                            Task {
                                do {
                                    try await appModel.generateSpatial3DImage()
                                } catch {
                                    print("Spatial3DImage generation failed: \(error.localizedDescription)")
                                    appModel.spatial3DImageState = .notGenerated
                                }
                            }
                        case .generating:
                            print("Spatial 3D Image is still generating...")
                            return
                        }
                    case .spatial3D:
                        ipc.desiredViewingMode = .mono
                        appModel.contentEntity.components.set(ipc)
                    default:
                        print("Unhandled viewing mode: \(ipc.viewingMode)")

                    }
                } label: {
                    switch appModel.contentEntity.observable.components[ImagePresentationComponent.self]?.viewingMode {
                    case .mono:
                        Text(appModel.spatial3DImageState == .generated ? "Show as 3D" : "Convert to 3D")
                    case .spatial3D:
                        Text("Show as 2D")
                    default:
                        Text("")
                    }
                }
            }.padding()
        }
        .glassBackgroundEffect()
        .onChange(of: appModel.imageIndex) {
            appModel.imageURL = appModel.imageURLs[appModel.imageIndex]
        }
    }
}
