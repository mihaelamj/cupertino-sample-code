/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher audio unit view model.
*/

import SwiftUI
import AudioToolbox
import CoreAudioKit

struct AudioUnitViewModel {
    var showAudioControls: Bool = false
    var showMIDIContols: Bool = false
    var title: String = "-"
    var message: String = "No audio unit loaded.."
    var viewController: ViewController?
}
