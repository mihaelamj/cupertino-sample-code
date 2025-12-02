/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main content view.
*/

import SwiftUI

struct ContentView: View {

    @StateObject var camera = Camera()
    
    var body: some View {
        HStack(spacing: 0) {
            camera.preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    Task {
                        await camera.start()
                    }
                }
            ConfigurationView(camera: camera)
                .background(MaterialView())
                .frame(width: 300)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
