/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main entry point.
*/

import SwiftUI

@main
struct CameraApp: App {
    init() {
        UINavigationBar.applyCustomAppearance()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

fileprivate extension UINavigationBar {
    static func applyCustomAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
