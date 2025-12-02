/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI app structure, which acts as the app's entry point and defines the volume the app uses to display the shader samples.
*/

import SwiftUI

@main
struct ShaderSamplesApp: App {
    var body: some Scene {
        WindowGroup {
            ShaderSamplesView()
        }
        .windowStyle(.volumetric)
    }
}
