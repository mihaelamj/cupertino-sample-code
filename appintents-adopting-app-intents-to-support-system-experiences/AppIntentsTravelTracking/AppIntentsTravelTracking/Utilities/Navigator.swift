/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that handles navigation in the app.
*/

import Foundation
import SwiftUI

@MainActor
@Observable
final class Navigator {
    static let shared = Navigator()

    var navigationOption: NavigationOption? = .landmarks
    var landmarkNavigationPath: [Landmark] = []
    var collectionNavigationPath: NavigationPath = .init()

    func navigate(to navigationOption: NavigationOption) {
        self.navigationOption = navigationOption
    }

    func navigate(to landmark: LandmarkEntity) async {
        navigationOption = .landmarks

        // Wait a little to ensure NavigationStack is loaded.
        try! await Task.sleep(for: .seconds(0.25))

        landmarkNavigationPath.append(landmark.landmark)
    }
    func navigate(to collection: Collection) async {
        navigationOption = .collections

        // Wait a little to ensure NavigationStack is loaded.
        try! await Task.sleep(for: .seconds(0.25))

        collectionNavigationPath.append(collection)
    }
}
