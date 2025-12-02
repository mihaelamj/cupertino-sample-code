/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `VideoProcessorApp`.
*/

import SwiftUI

@main
struct VideoProcessorApp: App {

    @State private var model: VideoProcessorModel
    @State private var processor: VideoProcessor

    init() {
        let model = VideoProcessorModel()
        let processor = VideoProcessor(model: model)
        self.model = model
        self.processor = processor
    }

    var body: some Scene {
        WindowGroup {
            VideoProcessorView()
                .environment(model)
                .environment(processor)
        }
    }
}
