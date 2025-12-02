/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Lightweight `CGImage` viewer.
*/

import SwiftUI
import Combine

struct ImageView: NSViewRepresentable {
    
    @ObservedObject var videoEffectsEngine: VideoEffectsEngine

    func makeNSView(context: Context) -> CoreGraphicsImageView {
        CoreGraphicsImageView()
    }

    func updateNSView(_ nsView: CoreGraphicsImageView, context: Context) {
        nsView.layer!.contents = videoEffectsEngine.outputImage
    }
    
    class CoreGraphicsImageView: NSView {
        init() {
            super.init(frame: .zero)

            wantsLayer = true
        
            layer!.contentsGravity = .resizeAspect
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
