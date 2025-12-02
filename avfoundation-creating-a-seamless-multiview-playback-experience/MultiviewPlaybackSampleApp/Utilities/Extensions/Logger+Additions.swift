/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extension to log general output with a specified subsystem.
*/

import os

extension Logger {
    
    static let general = Logger(subsystem: "com.apple.apple-samplecode.MultiviewPlaybackSampleApp", category: "General")
}
