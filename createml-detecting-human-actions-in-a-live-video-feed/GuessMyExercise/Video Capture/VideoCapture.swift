/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience class that configures the video capture session and
 creates a (video) frame publisher.
*/

import UIKit
import Combine
import AVFoundation

typealias Frame = CMSampleBuffer
typealias FramePublisher = AnyPublisher<Frame, Never>

protocol VideoCaptureDelegate: AnyObject {
    /// Informs the delegate when the Video Capture creates a new publisher.
    /// - Parameters:
    ///   - framePublisher: The new frame publisher.
    func videoCapture(_ videoCapture: VideoCapture,
                      didCreate framePublisher: FramePublisher)
}

/// Creates and maintains a capture session that publishes video frames.
///
/// A `VideoCapture` instance delivers video frames to clients by creating a
/// Combine publisher and responds to changes with:
/// - The device's orientation
/// - The user's camera selection, between the front- vs. back-facing camera
class VideoCapture: NSObject {
    /// The video capture's delegate.
    ///
    /// Set this property to receive pose and action prediction notifications.
    weak var delegate: VideoCaptureDelegate! {
        didSet { createVideoFramePublisher() }
    }

    /// A Boolean that indicates whether to publish video frames.
    ///
    /// Set to `false`  to stop publishing frames and reduce the app's power
    /// consumption, typically when the app doesn't need the camera's video
    /// frames such as showing dialog or other UI that obscures the camera
    /// preview.
    var isEnabled = true {
        didSet { isEnabled ? enableCaptureSession() : disableCaptureSession() }
    }

    /// The camera the app uses to configure the capture session.
    private var cameraPosition = AVCaptureDevice.Position.front {
        didSet { createVideoFramePublisher() }
    }

    /// The camera orientation the app uses to configure the capture session.
    private var orientation = AVCaptureVideoOrientation.portrait {
        didSet { createVideoFramePublisher() }
    }

    /// The source of the video frames.
    ///
    /// The app uses the capture session to select a video camera and configures
    /// the camera's resolution, orientation, and other options.
    /// When the capture session runs, it notifies its delegate (`self`) each
    /// time it captures a new frame from the video camera.
    private let captureSession = AVCaptureSession()

    /// The initial Combine publisher that forwards the video frames as the
    /// capture session produces them.
    private var framePublisher: PassthroughSubject<Frame, Never>?

    /// The worker thread the capture session uses to publish the video frames.
    private let videoCaptureQueue = DispatchQueue(label: "Video Capture Queue",
                                                  qos: .userInitiated)

    /// A camera option the app uses to configure the capture session.
    ///
    /// This Boolean indicates whether the capture session horizontally flips
    /// the image, as if looking at a reflection in a mirror.
    private var horizontalFlip: Bool {
        // Instruct the capture session to horizontally flip the image when the
        // user selects the front-facing camera.
        cameraPosition == .front
    }

    /// A Boolean that indicates whether the video capture minimize camera shake.
    private var videoStabilizationEnabled = false

    /// Changes the camera selection between the front- and back-facing cameras.
    func toggleCameraSelection() {
        cameraPosition = cameraPosition == .back ? .front : .back
    }

    /// Adjusts the video orientation to match the device's orientation.
    func updateDeviceOrientation() {
        // Retrieve the device's orientation from UIKit.
        let currentPhysicalOrientation = UIDevice.current.orientation

        // Use the device's physical orientation to orient the camera.
        switch currentPhysicalOrientation {

        // Default to portrait if face up, face down, or unknown.
        case .portrait, .faceUp, .faceDown, .unknown:
            // Use portrait for "flat" orientations.
            orientation = .portrait
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        case .landscapeLeft:
            // UIKit's "left" is the equivalent to AVFoundation's "right."
            orientation = .landscapeRight
        case .landscapeRight:
            // UIKit's "right" is the equivalent to AVFoundation's "left."
            orientation = .landscapeLeft

        // Use portrait as the default for any future, unknown cases.
        @unknown default:
            orientation = .portrait
        }
    }

    private func enableCaptureSession() {
        if !captureSession.isRunning { captureSession.startRunning() }
    }

    private func disableCaptureSession() {
        if captureSession.isRunning { captureSession.stopRunning() }
    }
}

// MARK: - AV Capture Video Data Output Sample Buffer Delegate

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput frame: Frame,
                       from connection: AVCaptureConnection) {

        // Forward the frame through the publisher.
        framePublisher?.send(frame)
    }
}

// MARK: - Capture Session Configuration
extension VideoCapture {
    /// Creates a video frame publisher by starting or reconfiguring the
    /// video capture session.
    private func createVideoFramePublisher() {
        // (Re)configure the capture session.
        guard let videoDataOutput = configureCaptureSession() else { return }

        // Create a new passthrough subject that publishes frames to subscribers.
        let passthroughSubject = PassthroughSubject<Frame, Never>()

        // Keep a reference to the publisher.
        framePublisher = passthroughSubject

        // Set the video capture as the video output's delegate.
        videoDataOutput.setSampleBufferDelegate(self, queue: videoCaptureQueue)

        // Create a generic publisher by type erasing the passthrough publisher.
        let genericFramePublisher = passthroughSubject.eraseToAnyPublisher()

        // Send the publisher to the `VideoCapture` instance's delegate.
        delegate.videoCapture(self, didCreate: genericFramePublisher)
    }

    /// Configures or reconfigures the session to the new camera settings.
    private func configureCaptureSession() -> AVCaptureVideoDataOutput? {
        disableCaptureSession()

        guard isEnabled else {
            // Leave the camera disabled.
            return nil
        }

        // (Re)start the capture session after this method returns.
        defer { enableCaptureSession() }

        // Tell the capture session to start configuration.
        captureSession.beginConfiguration()

        // Finalize the configuration after this method returns.
        defer { captureSession.commitConfiguration() }

        let input = AVCaptureDeviceInput.createCameraInput(position: cameraPosition)

        let output = AVCaptureVideoDataOutput.withPixelFormatType(kCVPixelFormatType_32BGRA)

        let success = configureCaptureConnection(input, output)
        return success ? output : nil
    }

    /// Sets the connection's orientation, image mirroring, and video stabilization.
    private func configureCaptureConnection(_ input: AVCaptureDeviceInput?,
                                            _ output: AVCaptureVideoDataOutput?) -> Bool {

        guard let input = input else { return false }
        guard let output = output else { return false }

        // Clear inputs and outputs from the capture session.
        captureSession.inputs.forEach(captureSession.removeInput)
        captureSession.outputs.forEach(captureSession.removeOutput)

        guard captureSession.canAddInput(input) else {
            print("The camera input isn't compatible with the capture session.")
            return false
        }

        guard captureSession.canAddOutput(output) else {
            print("The video output isn't compatible with the capture session.")
            return false
        }

        // Add the input and output to the capture session.
        captureSession.addInput(input)
        captureSession.addOutput(output)

        // Set the video camera to run at the action classifier's frame rate.
        let modelFrameRate = ExerciseClassifier.frameRate
        guard input.device.configureFrameRate(modelFrameRate) else { return false }

        // This capture session must only have one connection.
        guard captureSession.connections.count == 1 else {
            let count = captureSession.connections.count
            print("The capture session has \(count) connections instead of 1.")
            return false
        }

        // Configure the first, and only, connection.
        guard let connection = captureSession.connections.first else {
            print("Getting the first/only capture-session connection shouldn't fail.")
            return false
        }

        if connection.isVideoOrientationSupported {
            // Set the video capture's orientation to match that of the device.
            connection.videoOrientation = orientation
        }

        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = horizontalFlip
        }

        if connection.isVideoStabilizationSupported {
            if videoStabilizationEnabled {
                connection.preferredVideoStabilizationMode = .standard
            } else {
                connection.preferredVideoStabilizationMode = .off
            }
        }

        // Discard newer frames if the app is busy with an earlier frame.
        output.alwaysDiscardsLateVideoFrames = true

        return true
    }
}
