/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Abstract:
 Supporting data types for the app.
*/

import AVFoundation
import SwiftUI

// MARK: - Camera supporting types

/// An enumeration that describes the current status of the camera.
enum CameraStatus {
    /// The initial status on creation.
    case unknown
    /// A status that indicates a person disallows access to the camera.
    case unauthorized
    /// A status that indicates the camera failed to start.
    case failed
    /// A status that indicates the camera is successfully running.
    case running
    /// A status that indicates higher-priority media processing is interrupting the camera.
    case interrupted
}

/// An enumeration that defines the activity states the capture service supports.
///
/// This type provides feedback to the UI regarding the active status of the `CaptureService` actor.
enum CaptureActivity {
    case idle
    /// A status that indicates the capture service is performing movie capture.
    case movieCapture(duration: TimeInterval = 0.0)
    
    var currentTime: TimeInterval {
        if case .movieCapture(let duration) = self {
            return duration
        }
        return .zero
    }
    
    var isRecording: Bool {
        if case .movieCapture(_) = self {
            return true
        }
        return false
    }
}

enum CameraOrientation {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
    case unknown
    
    init(videoRotationAngle: CGFloat, front: Bool) {
        self = CameraOrientation.unknown
        if front {
            // The landscape-left orientation.
            if videoRotationAngle == 0.0 {
                self = CameraOrientation.landscapeLeft
            // The portrait orientation.
            } else if videoRotationAngle == 90.0 {
                self = CameraOrientation.portrait
            // The landscape-right orientation.
            } else if videoRotationAngle == 180.0 {
                self = CameraOrientation.landscapeRight
            // The portrait upside-down orientation.
            } else if videoRotationAngle == 270.0 {
                self = CameraOrientation.portraitUpsideDown
            }
        } else {
            // The landscape-right orientation.
            if videoRotationAngle == 0.0 {
                self = CameraOrientation.landscapeRight
            // The portrait orientation.
            } else if videoRotationAngle == 90.0 {
                self = CameraOrientation.portrait
            // The landscape-left orientation.
            } else if videoRotationAngle == 180.0 {
                self = CameraOrientation.landscapeLeft
            // The portrait upside-down orientation.
            } else if videoRotationAngle == 270.0 {
                self = CameraOrientation.portraitUpsideDown
            }
        }
    }
}

/// An enumeration that describes the zoom type - zoom in or zoom out.
enum CameraZoomType {
    case increase
    case decrease
}

/// A structure that contains the uniform type identifier and the movie URL.
struct Movie: Sendable {
    /// The temporary location of the file on disk.
    let url: URL
}

enum CameraError: Error {
    case videoDeviceUnavailable
    case audioDeviceUnavailable
    case addInputFailed
    case addOutputFailed
    case setupFailed
    case deviceChangeFailed
}

protocol OutputService {
    associatedtype Output: AVCaptureOutput
    var output: Output { get }
    var captureActivity: CaptureActivity { get }
    func updateConfiguration(for device: AVCaptureDevice)
    func setVideoRotationAngle(_ angle: CGFloat)
}

extension OutputService {
    func setVideoRotationAngle(_ angle: CGFloat) {
        // Set the rotation angle on the output object's video connection.
        output.connection(with: .video)?.videoRotationAngle = angle
    }
    
    func updateConfiguration(for device: AVCaptureDevice) {}
    
    func getVideoRotationAngle() -> CGFloat {
        // Set the rotation angle on the output object's video connection.
        output.connection(with: .video)?.videoRotationAngle ?? 0.0
    }
}

// MARK: - DockKit supporting types

@Observable
/// An object that stores the state of a person's enabled DockKit features.
class DockAccessoryFeatures {
    var isTapToTrackEnabled = false
    var isTrackingSummaryEnabled = false
    var isSetROIEnabled = false
    var trackingMode: TrackingMode = .system
    var framingMode: FramingMode = .auto
    
    var current: EnabledDockKitFeatures {
        .init(isTapToTrackEnabled: isTapToTrackEnabled,
              isTrackingSummaryEnabled: isTrackingSummaryEnabled,
              isSetROIEnabled: isSetROIEnabled,
              trackingMode: trackingMode, framingMode: framingMode)
    }
}

@Observable
/// An object that stores the tracking summary for a person.
class DockAccessoryTrackedPerson: Identifiable {
    let uuid = UUID()
    let saliency: Int?
    var rect: CGRect
    let speaking: Double?
    let looking: Double?
    
    init(saliency: Int? = nil, rect: CGRect, speaking: Double? = nil, looking: Double? = nil) {
        self.saliency = saliency
        self.rect = rect
        self.speaking = speaking
        self.looking = looking
    }
     
    func update(rect: CGRect) {
        self.rect = rect
    }
}

struct EnabledDockKitFeatures {
    let isTapToTrackEnabled: Bool
    let isTrackingSummaryEnabled: Bool
    let isSetROIEnabled: Bool
    let trackingMode: TrackingMode
    let framingMode: FramingMode
}

/// A protocol to perform DockKit-related functions.
protocol DockAccessoryTrackingDelegate: AnyObject {
    func track(metadata: [AVMetadataObject], sampleBuffer: CMSampleBuffer?,
               deviceType: AVCaptureDevice.DeviceType, devicePosition: AVCaptureDevice.Position)
}

/// A protocol to perform capture-related functions.
protocol CameraCaptureDelegate: AnyObject {
    func startOrStartCapture()
    func switchCamera()
    func zoom(type: CameraZoomType, factor: Double)
    func convertToViewSpace(from rect: CGRect) async -> CGRect
}

/// An enumeration that describes the current status of the camera.
enum DockAccessoryStatus {
    /// A status that indicates there's no accessory connected.
    case disconnected
    /// A status that indicates an accessory is connected.
    case connected
    /// A status that indicates an accessory is connected and tracking.
    case connectedTracking
}

/// An enumeration that describes the current status of the camera.
enum DockAccessoryBatteryStatus {
    /// A status that indicates the battery status is unavailable.
    case unavailable
    /// A status that indicates the battery status is available.
    case available(percentage: Double = 0.0, charging: Bool = false)
    
    var percentage: Double {
        if case .available(let percentage, _) = self {
            return percentage
        }
        return 0.0
    }

    var charging: Bool {
        if case .available(_, let charging) = self {
            return charging
        }
        return false
    }
}

enum FramingMode: String, CaseIterable, Identifiable {
    case auto = "Frame Auto"
    case center = "Frame Center"
    case left = "Frame Left"
    case right = "Frame Right"
    public var id: Self { self }
    
    func symbol() -> some View {
        switch self {
        case .auto:
            return Image(systemName: "sparkles")
        case .center:
            return Image(systemName: "person.crop.rectangle")
        case .left:
            return Image(systemName: "inset.filled.rectangle.and.person.filled")
        case .right:
            return Image(systemName: "inset.filled.rectangle.and.person.filled")
        }
    }
}

enum TrackingMode: String, CaseIterable, Identifiable {
    case system = "System Tracking"
    case custom = "Custom Tracking"
    case manual = "Manual Control"
    public var id: Self { self }
}

enum Animation: String, CaseIterable, Identifiable {
    case yes
    case nope
    case wakeup
    case kapow
    public var id: Self { self }
}

enum ChevronType: String, CaseIterable, Identifiable {
    case tiltUp
    case tiltDown
    case panLeft
    case panRight
    public var id: Self { self }
}
