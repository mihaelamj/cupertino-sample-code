/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit application file.
*/


import CoreMIDI
import SwiftUI

@main
struct vDSP_audio_unitApp: App {
    @ObservedObject private var hostModel = AudioUnitHostModel()

    var body: some Scene {
        WindowGroup {
            ContentView(hostModel: hostModel)
        }
    }
}
