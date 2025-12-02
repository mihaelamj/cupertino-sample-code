/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays controls to capture, switch cameras, and view the last captured media item.
*/

import SwiftUI
import PhotosUI

/// A view that displays controls to capture, switch cameras, and view the last captured media item.
struct MainToolbar<CameraModel: Camera>: View {

    let toolbarHeight: CGFloat = 80
    @State var camera: CameraModel
    
    var body: some View {
        HStack {
			ThumbnailButton(camera: camera)
            Spacer()
            CaptureButton(camera: camera)
            Spacer()
            SwitchCameraButton(camera: camera)
        }
        .foregroundColor(.white)
        .frame(height: toolbarHeight)
        .padding([.leading, .trailing])
    }
}

#if DEBUG
#Preview {
    MainToolbar(camera: PreviewCameraModel())
}
#endif
