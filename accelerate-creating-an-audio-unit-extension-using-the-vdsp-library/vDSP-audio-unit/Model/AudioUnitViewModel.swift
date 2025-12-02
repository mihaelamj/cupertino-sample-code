/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit view model.
*/

import SwiftUI
import AudioToolbox
import CoreAudioKit

struct AudioUnitViewModel {
    var showAudioControls: Bool = false
    var showMIDIContols: Bool = false
    var title: String = "-"
    var message: String = "No Audio Unit loaded.."
    var viewController: ViewController?
}
