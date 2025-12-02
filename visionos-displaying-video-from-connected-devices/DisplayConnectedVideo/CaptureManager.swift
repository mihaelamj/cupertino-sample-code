/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An actor to manage capturing video from a selected device.
*/

@preconcurrency import AVFoundation

actor CaptureManager: NSObject {
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private let sessionQueue = DispatchSerialQueue(label: "com.example.apple-samplecode.sessionQueue")
    
    /// Sets the session queue as the actor's executor.
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }
    
    /// The video renderer from the `AVSampleBufferDisplayLayer`
    /// this app uses to display video.
    nonisolated private let videoRenderer: AVSampleBufferVideoRenderer
    
    init(videoRenderer: AVSampleBufferVideoRenderer) {
        self.videoRenderer = videoRenderer
                
        super.init()
        
        Task {
            // Perform initial capture session configuration.
            await setUpSession()
            await observeFlushToResumeDecoding()
        }
    }
        
    private func setUpSession() {
        // Bracket the following configuration in a begin/commit configuration pair.
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Drop frames that don't render in a timely manner.
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        } else {
            assertionFailure("Unable to add video data output to the capture session.")
        }
    }
    
    /// Stops capture from the previously selected device and, if provided, begins capture from the provided device.
    /// - Parameter device: The device to capture video from, or nil to stop capture altogether.
    func select(device: Device?) {
        // Bracket the following configuration in a begin/commit configuration pair.
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Remove previous input, if it exists.
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        
        // Prepare the renderer to receive content from a new device.
        videoRenderer.flush(removingDisplayedImage: true)

        // Return early if the passed device is nil.
        guard let captureDevice = device?.captureDevice else { return }
        
        do {
            let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            
            /// In the context of this sample, this check generally passes because `ContentView`
            /// displays a message and terminates when the system denies access to the camera.
            precondition(authorizationStatus == .authorized,
                         "Camera authorization is required to set up a device capture session.")
            
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Add the new input, if possible.
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                assertionFailure("Unable to add the input to the capture session.")
            }
        } catch {
            fatalError("Unable to create input for the device. \(error)")
        }
    }

    /// Begin the flow of data from the capture session's inputs to its outputs.
    func start() {
        captureSession.startRunning()
    }
    
    private func observeFlushToResumeDecoding() {
        Task {
            for await _ in NotificationCenter.default.notifications(named: AVSampleBufferVideoRenderer
                .requiresFlushToResumeDecodingDidChangeNotification,
                                                                    object: videoRenderer) {
                videoRenderer.flush()
            }
        }
    }
}

extension CaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // If the renderer is ready for more data, queue the sample buffer for presentation.
        if videoRenderer.isReadyForMoreMediaData {
            videoRenderer.enqueue(sampleBuffer)
        }
    }
}
