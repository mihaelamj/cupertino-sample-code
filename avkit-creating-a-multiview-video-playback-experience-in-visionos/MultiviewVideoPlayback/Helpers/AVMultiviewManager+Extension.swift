/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The helper function for setting the `contentSelectionViewController` to a SwiftUI `View`.
*/

import AVKit
import SwiftUI

extension AVMultiviewManager {
    static func setContentSelectionView<Content: View>(_ rootView: Content) {
        let hostingController = UIHostingController(rootView: rootView)
        let contentSelectionViewController = AVContentSelectionViewController()
        contentSelectionViewController.preferredContentSize = .init(width: 1200, height: 340.0)

        // Add the `hostingController` and its view to the empty `contentSelectionViewController`.
        contentSelectionViewController.addChild(hostingController)
        contentSelectionViewController.view.addSubview(hostingController.view)

        // Notify the `hostingController` that the move is complete.
        hostingController.didMove(toParent: contentSelectionViewController)

        // Set the constraints so that the `hostingController` matches the size of the `contentSelectionViewController`.
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentSelectionViewController.view.leadingAnchor.constraint(equalTo: hostingController.view.leadingAnchor),
            contentSelectionViewController.view.trailingAnchor.constraint(equalTo: hostingController.view.trailingAnchor),
            contentSelectionViewController.view.topAnchor.constraint(equalTo: hostingController.view.topAnchor),
            contentSelectionViewController.view.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor)
        ])

        AVMultiviewManager.default.contentSelectionViewController = contentSelectionViewController
    }
}
