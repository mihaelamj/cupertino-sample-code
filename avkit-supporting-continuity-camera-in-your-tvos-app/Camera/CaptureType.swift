/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Enumeration cases for media capture type and state.
*/

import Foundation

enum CaptureType: String, CaseIterable {

    case photo
    case video
    case audio

    static var allCases: [CaptureType] {
        return [.photo, .video, .audio]
    }
}

enum CaptureState: CustomStringConvertible {

    case recording(startTime: Date)
    case failed(reason: String)

    var description: String {
        switch self {
            case .recording(let startTime):
                return "recording: \(String(describing: startTime))"
            case .failed(let reason):
                return "failed: \(reason)"
        }
    }
}
