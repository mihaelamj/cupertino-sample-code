/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays controls to capture media items, switch cameras, and view the most recently captured media item.
*/

import SwiftUI
import PhotosUI

/// A view that displays controls to capture media items, switch cameras, and view the most recently captured media item.
struct MainToolbar<CameraModel: Camera, DockControllerModel: DockController>: View {
    
    @State var camera: CameraModel
    @State var dockController: DockControllerModel
    
    var body: some View {
        HStack {
            DockKitMenu(dockController: dockController)
            Spacer()
            CaptureButton(camera: camera)
            Spacer()
            SwitchCameraButton(camera: camera)
        }
        .foregroundColor(.white)
        .font(.system(size: 24))
        .frame(width: width, height: height)
        .padding([.leading, .trailing])
    }
    
    var width: CGFloat? { nil }
    var height: CGFloat? { 80 }
}

#Preview {
    MainToolbar(camera: PreviewCameraModel(), dockController: PreviewDockControllerModel())
}
