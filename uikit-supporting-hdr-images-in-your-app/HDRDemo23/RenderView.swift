/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The low-level view to use in the editing mode to maximize performance.
*/

import SwiftUI
import CoreVideo
import CoreImage
import Combine

#if canImport(UIKit)
import UIKit

struct PixelBufferView: UIViewRepresentable {

    let pixelBuffer: CVPixelBuffer?

    func makeUIView(context: Context) -> UIView {

        let view = UIView()
        let layer = view.layer
        layer.contents = pixelBuffer
        layer.wantsExtendedDynamicRangeContent = true
        layer.contentsGravity = .resizeAspect
        layer.actions = [
            "contents": NSNull()
        ]
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        view.layer.contents = pixelBuffer
    }
}
#else
import AppKit

struct PixelBufferView: NSViewRepresentable {

    let pixelBuffer: CVPixelBuffer?

    func makeNSView(context: Context) -> NSView {

        let view = NSView()
        view.wantsLayer = true
        let layer = CALayer()
        layer.contents = pixelBuffer
        layer.wantsExtendedDynamicRangeContent = true
        layer.contentsGravity = .resizeAspect
        layer.actions = [
            "contents": NSNull()
        ]
        view.layer = layer
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        view.layer?.contents = pixelBuffer
    }
}

#endif

struct RenderView: View {

    var asset: EditedAsset

    var body: some View {
        PixelBufferView(pixelBuffer: asset.pixelBuffer)
    }

}
