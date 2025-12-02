/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher application file.
*/

import CoreMIDI
import SwiftUI

@main
struct BNNSBitcrusherApp: App {
    @ObservedObject private var hostModel = AudioUnitHostModel()

    var body: some Scene {
        WindowGroup {
            ContentView(hostModel: hostModel)
        }
    }
}
