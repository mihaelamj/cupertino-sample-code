/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that contains the Canvas's selected image.
*/

import Foundation
import SwiftUI
import PhotosUI

struct PhotoPlacementView: View {
    @State private var location: CGPoint = CGPoint(x: 50, y: 50)
    @ObservedObject var canvas: Canvas

    var body: some View {
        if let imageData = canvas.selectedImageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                 .resizable()
                 .scaledToFit()
                 .frame(width: 250, height: 250)
                 .position(location)
                 .gesture(simpleDrag)
                 .onLongPressGesture {
                     canvas.finishImagePlacement(location: location)
                 }
         }
    }

    var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                self.location = value.location
            }
    }
}
