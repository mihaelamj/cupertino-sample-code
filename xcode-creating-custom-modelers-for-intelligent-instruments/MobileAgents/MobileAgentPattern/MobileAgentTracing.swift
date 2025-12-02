/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
MobileAgentTracing contains a few utilities for better debugging/instrumentation.
*/

import Foundation

protocol DiagnosticCodeExpressable {
    func diagnosticsTypeCode() -> UInt32
}

extension DiagnosticCodeExpressable {
    func diagnosticsTypeCode() -> UInt32 {
        return 0
    }
   
}

protocol MockDelayable {
    var mockDelay: useconds_t { get set }
}

extension MockDelayable {
    func injectMockDelay() {
        if mockDelay > 0 {
            usleep(mockDelay)
        }
    }
}
