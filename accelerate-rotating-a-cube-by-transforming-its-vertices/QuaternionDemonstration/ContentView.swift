/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The cube rotation UI file.
*/

import SwiftUI
import SceneKit

struct ContentView: View {
    
    @EnvironmentObject var cubeRotation: CubeRotation
    
    var body: some View {
        VStack {
            SceneView(scene: cubeRotation.scene)
        }
        .padding()
        .toolbar(content: {
            Text("Use Spline")
            Toggle("Use spline",
                   isOn: $cubeRotation.useSpline).toggleStyle(.switch)
        })
    }
}
