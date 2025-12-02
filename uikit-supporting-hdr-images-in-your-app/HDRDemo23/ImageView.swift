/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main one-up view for HDR images using UIKit or AppKit.
*/

import SwiftUI
#if canImport(UIKit)
import UIKit

struct ImageView: UIViewRepresentable {

    // Set up a common reader for all UIImage read requests.
    static let reader: UIImageReader = {
        var config = UIImageReader.Configuration()
        config.prefersHighDynamicRange = true
        return UIImageReader(configuration: config)
    }()

    let asset: Asset?

    func makeUIView(context: Context) -> UIImageView {

        let view = UIImageView()
        view.preferredImageDynamicRange = .high
        update(view)

        // Set this view to fit itself to the parent view.
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)

        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        update(view)
    }

    func update(_ view: UIImageView) {
        if let url = asset?.file {
            view.image = ImageView.reader.image(contentsOf: url)
        } else if let data = asset?.data {
            view.image = ImageView.reader.image(data: data)
        } else {
            view.image = UIImage()
        }
    }

}
#else
import AppKit

struct ImageView: NSViewRepresentable {

    let asset: Asset?

    func makeNSView(context: Context) -> NSImageView {

        let view = NSImageView()
        view.preferredImageDynamicRange = .high
        update(view)

        // Set this view to fit itself to the parent view.
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)

        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        update(view)
    }

    func update(_ view: NSImageView) {
        if let url = asset?.file {
            view.image = NSImage(contentsOf: url)
        } else if let data = asset?.data {
            view.image = NSImage(data: data)
        } else {
            view.image = nil
        }
    }
}

#endif
