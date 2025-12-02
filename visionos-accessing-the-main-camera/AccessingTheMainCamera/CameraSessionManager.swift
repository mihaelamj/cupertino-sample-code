/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Renders the camera frames from `CameraFrameProvider` to an `AVSampleBufferDisplayLayer`.
*/

import ARKit
import AVFoundation
import SwiftUI

@Observable
@MainActor
final class CameraSessionManager {

    // MARK: - Types
    /// `MainCamera` view uses this enumeration to display a picker containing the available camera settings.
    enum CameraConfiguration: String, Equatable, CaseIterable, CustomStringConvertible {
        
        static let `default` = CameraConfiguration.leftMono

        case leftMono = "Left Mono"
        case rightMono = "Right Mono"
        case stereo = "Stereo"
        case stereoCorrected = "Stereo Corrected"
        
        var cameraPositions: [CameraFrameProvider.CameraPosition] {
            switch self {
            case .leftMono:
                [.left]
            case .rightMono:
                [.right]
            case .stereo, .stereoCorrected:
                [.left, .right]
            }
        }
        
        var cameraRectification: CameraFrameProvider.CameraRectification {
            switch self {
                case .stereoCorrected:
                    .stereoCorrected
                default: .mono
            }
        }
        
        var description: String {
            self.rawValue
        }
    }
    
    // MARK: - Frame capture and rendering
    private var arkitSession: ARKitSession?
    private var cameraFrameProvider: CameraFrameProvider?
    private var leftCameraFeed = CameraFeed()
    private var rightCameraFeed = CameraFeed()
    
    // MARK: - Availability checks
    private(set) var accessDenied = false
    static let isSupported = CameraFrameProvider.isSupported
    
    // MARK: - Configuration
    /// The configuration for the camera frame format.
    var configuration: CameraConfiguration = .default {
        didSet {
            handleCameraSettingChange()
        }
    }
        
    /// The resolution for the camera frames.
    var isHighResolution: Bool = true {
        didSet {
            handleCameraSettingChange()
        }
    }
    
    // MARK: Display layers
    /// The layer displaying the left camera preview.
    var leftPreview: AVSampleBufferDisplayLayer {
        leftCameraFeed.preview
    }
    
    /// The layer displaying the right camera preview.
    var rightPreview: AVSampleBufferDisplayLayer {
        rightCameraFeed.preview
    }
    
    // MARK: - External capture life cycle
    /// Begin reading and rendering the main camera's frames.
    func run() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.runCameraFrameProvider()
            }
            
            group.addTask {
                await self.observeCameraAccess()
            }
        }
    }
    
    // MARK: - Internal capture life cycle
    private func clearCameraFeeds() async {
        try? await leftCameraFeed.update(using: nil)
        try? await rightCameraFeed.update(using: nil)
    }
    
    private func handleCameraSettingChange() {
        // Only restart when ARKit is running.
        guard cameraFrameProvider?.state == .running else {
           return
        }
        
        Task {
            await restart()
        }
    }
    
    private func observeCameraAccess() async {
        // The sample uses this instance to monitor for authorization changes.
        let session = ARKitSession()
        
        for await event in session.events {
            guard case .authorizationChanged(let type, let status) = event,
                  type == .cameraAccess else {
                continue
            }

            if status == .denied {
                accessDenied = true
                await clearCameraFeeds()
            } else if status == .allowed && accessDenied {
                accessDenied = false
                await restart()
            }
        }
    }
    
    private func observeCameraFrameUpdates() async {
        guard let cameraFrameProvider else { return }
        
        // Find the `CameraVideoFormat` that corresponds to the `CameraConfiguration`.
        let formats = CameraVideoFormat
            .supportedVideoFormats(for: .main, cameraPositions: configuration.cameraPositions)
            .filter({ $0.cameraRectification == configuration.cameraRectification })
        
        // Find the resolution format.
        let desiredFormat = isHighResolution ?
        formats.max { $0.frameSize.height < $1.frameSize.height }
        : formats.min { $0.frameSize.height < $1.frameSize.height }

        // Request an asynchronous sequence of camera frames.
        guard let desiredFormat,
              let cameraFrameUpdates = cameraFrameProvider.cameraFrameUpdates(for: desiredFormat) else {
            return
        }
        
        for await cameraFrame in cameraFrameUpdates {
            guard cameraFrameProvider.state == .running else {
                continue
            }
            
            if let leftSample = cameraFrame.sample(for: .left) {
                try? await leftCameraFeed.update(using: leftSample)
            }
            
            if let rightSample = cameraFrame.sample(for: .right) {
                try? await rightCameraFeed.update(using: rightSample)
            }
        }
    }
       
    func restart() async {
        arkitSession?.stop()
        await clearCameraFeeds()
        await runCameraFrameProvider()
    }
        
    private func runCameraFrameProvider() async {
        let arkitSession = ARKitSession()
        let authorizationStatus = await arkitSession.requestAuthorization(for: [.cameraAccess])
        
        guard authorizationStatus[.cameraAccess] == .allowed else {
            accessDenied = true
            
            return
        }
        
        let cameraFrameProvider = CameraFrameProvider()
        try? await arkitSession.run([cameraFrameProvider])
        self.arkitSession = arkitSession
        self.cameraFrameProvider = cameraFrameProvider
        
        await observeCameraFrameUpdates()
    }
}
