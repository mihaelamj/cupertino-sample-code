/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages a movie-capture output to record videos.
*/

import AVFoundation
import Combine

/// An object that manages a movie-capture output to record videos.
final class MovieCapture: NSObject, OutputService {
    
    /// A value that indicates the current state of movie capture.
    @Published private(set) var captureActivity: CaptureActivity = .idle
    
    /// A value that indicates the currently detected metadata objects.
    @Published private(set) var metadataObjects: [AVMetadataObject] = []
    
    /// The capture outputs for this service.
    var output: AVCaptureMovieFileOutput {
        get {
            return movieOutput
        }
        
        set {
            movieOutput = newValue
        }
    }
    
    /// The movie data output.
    var movieOutput: AVCaptureMovieFileOutput
    
    /// The video data output to get video frames.
    var videoOutput: AVCaptureVideoDataOutput
    
    /// The metadata output to get detected observations.
    var metadataOutput: AVCaptureMetadataOutput
    
    // The newest sample buffer.
    var sampleBuffer: CMSampleBuffer?
    
    // A delegate object to respond to movie-capture events.
    private var movieCaptureDelegate: MovieCaptureDelegate?
    
    // The interval for updating the recording time.
    private let refreshInterval = TimeInterval(0.25)
    private var timerCancellable: AnyCancellable?
    
    // A Boolean value that indicates whether the currently selected camera's
    // active format supports HDR.
    private var isHDRSupported = false
    
    override init() {
        // Initialize the outputs for movie/video and metadata.
        movieOutput = AVCaptureMovieFileOutput()
        videoOutput = AVCaptureVideoDataOutput()
        metadataOutput = AVCaptureMetadataOutput()
        
        super.init()
        
        // Set the video-capture and metadata-capture delegates.
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue(label: "MetaDataOutputQueue"))
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoframesOutputQueue"))

    }
    
    // MARK: - Capturing a movie
    
    /// Starts movie recording.
    func startRecording() {
        // Return early if already recording.
        guard !movieOutput.isRecording else { return }
        
        guard let connection = movieOutput.connection(with: .video) else {
            fatalError("Configuration error. No video connection found.")
        }

        // Configure connection for HEVC capture.
        if movieOutput.availableVideoCodecTypes.contains(.hevc) {
            movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
        }

        // Enable video stabilization if the connection supports it.
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
        
        // Start a timer to update the recording time.
        startMonitoringDuration()
        
        movieCaptureDelegate = MovieCaptureDelegate()
        movieOutput.startRecording(to: URL.movieFileURL, recordingDelegate: movieCaptureDelegate!)
    }
    
    /// Stops movie recording.
    /// - Returns: A `Movie` object that represents the captured movie.
    func stopRecording() async throws -> Movie {
        // Use a continuation to adapt the delegate-based capture API to an asynchronous interface.
        return try await withCheckedThrowingContinuation { continuation in
            // Set the continuation on the delegate to handle the capture result.
            movieCaptureDelegate?.continuation = continuation
            
            /// Stops recording, which causes the output to call the `MovieCaptureDelegate` object.
            movieOutput.stopRecording()
            stopMonitoringDuration()
        }
    }
    
    func setMovieRotationAngle(_ angle: CGFloat) {
        movieOutput.connection(with: .video)?.videoRotationAngle = angle
    }
    
    // MARK: - Movie-capture delegate
    /// A delegate object that responds to the capture output finalizing the movie recording.
    private class MovieCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
        
        var continuation: CheckedContinuation<Movie, Error>?
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                        from connections: [AVCaptureConnection], error: Error?) {
            if let error {
                // If an error occurs, throw it to the caller.
                continuation?.resume(throwing: error)
            } else {
                // Return a new movie object.
                continuation?.resume(returning: Movie(url: outputFileURL))
            }
        }
    }
    
    // MARK: - Monitoring recorded duration
    
    // Starts a timer to update the recording time.
    private func startMonitoringDuration() {
        captureActivity = .movieCapture()
        timerCancellable = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                // Poll the movie output for its recorded duration.
                let duration = movieOutput.recordedDuration.seconds
                logger.notice("duration is \(duration)")
                captureActivity = .movieCapture(duration: duration)
            }
    }
    
    /// Stops the timer and resets the time to `CMTime.zero`.
    private func stopMonitoringDuration() {
        timerCancellable?.cancel()
        captureActivity = .idle
    }
}

// MARK: - Metadata-capture delegate
extension MovieCapture: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.metadataObjects = metadataObjects
    }
}

// MARK: - Video-capture delegate
extension MovieCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.sampleBuffer = sampleBuffer
    }
}
