/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vImage polynomial transform app file.
*/


import SwiftUI

@main
struct vImagePolynomialApp: App {
    @StateObject private var polynomialTransformer = PolynomialTransformer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(polynomialTransformer)
        }
    }
}
