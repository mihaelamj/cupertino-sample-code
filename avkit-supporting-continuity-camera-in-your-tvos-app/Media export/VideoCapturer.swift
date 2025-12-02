/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that captures and stores videos as movie files.
*/

import AVFoundation
import Photos

/// Records and saves videos as tempory movie files and attempts to add them to
/// the device's photo library.
class VideoCapturer: NSObject, ObservableObject {

    /// The video capturer's current state.
    ///
    /// The value is typically `.recording`, or `nil` when not in use.
    @Published public var captureState: CaptureState?

    /// An output that saves a video from a capture session to a movie file.
    public let movieFileOutput = AVCaptureMovieFileOutput()

    // MARK: Recording

    /// Initiates a video recording with a capture session's camera.
    public func startRecording(with camera: CaptureManager) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy_HH-mm-ss-SSSS"

        let outputFileName = dateFormatter.string(from: .now) + ".mov"
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputFileURL = tempDirectory.appending(path: outputFileName)

        guard let movieFileConnection = movieFileOutput.connection(with: .video) else {
            print("Unable to create an output video file.")
            return
        }

        // Sets the movie file's codec to HVEC.
        let settings = [AVVideoCodecKey: AVVideoCodecType.hevc]
        movieFileOutput.setOutputSettings(settings, for: movieFileConnection)

        print("Starting a video recording...")
        movieFileOutput.startRecording(to: outputFileURL,
                                       recordingDelegate: self)
    }

    ///  Ends the video capture.
    public func stopRecording() {
        print("Ending the video recording.")
        movieFileOutput.stopRecording()
    }

    /// Saves a captured video to the device's photo library.
    /// - Parameter file: A URL to a movie file.
    public func addVideoToLibrary(_ movieFile: URL) async {
        // Checks or requests access to the photo library.
        let result = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard result == .authorized else {
            print("App doesn't have write-access to the photo library.")
            return
        }

        // Adds the movie file to the library.
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true

                // Creates a movie file request that submits the movie file.
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .video,
                                            fileURL: movieFile,
                                            options: options)
            }
            print("Added video from \(movieFile.absoluteString) to library.")
        } catch let error {
            let description = String(describing: error)
            print("Unable to add movie file to library due to: \(description)")
        }
    }
}

extension VideoCapturer: AVCaptureFileOutputRecordingDelegate {

    /// Delegate method the file output calls when a recording finishes.
    /// - Parameters:
    ///   - output: The output that's saving the movie file.
    ///   - movieFile: The location of the movie file in the file system.
    ///   - connections: An array of capture instances that represent the movie
    ///   file's sources
    ///   - error: An error instance if the output experiences a problem;
    ///   otherwise `nil`.
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo movieFile: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        let path = movieFile.absoluteString

        if let error {
            // Changes the state to an error condition.
            let description = String(describing: error)
            captureState = .failed(reason: description)

            print("Trouble recording video to a movie file")
            print("\t\(path)")
            print("Due to error: \(description)")
        } else {
            // Clears the state, which implies success.
            captureState = nil

            print("Finished recording video to movie file.")
            print("\t\(path)")

            Task {
                await self.addVideoToLibrary(movieFile)
            }
        }
    }

    /// Delegate method the file output calls when a recording starts.
    /// - Parameters:
    ///   - output: The output that's saving the movie file.
    ///   - movieFile: The location of the movie file in the file system.
    ///   - connections: An array of capture instances that represent the movie
    ///   file's sources.
    func fileOutput(_ output: AVCaptureFileOutput,
                    didStartRecordingTo movieFile: URL,
                    from connections: [AVCaptureConnection]) {
        print("Started recording video to movie file")
        print("\t\(movieFile.absoluteString)")

        // Changes the state with a timestamp for the UI's Timer View.
        captureState = .recording(startTime: .now)
    }
}
