/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Configures a capture device's frame rate range around a target frame rate.
*/

import AVFoundation

extension AVCaptureDevice {
    /// Configures the capture device to use the best available frame rate range
    /// around the target frame rate.
    /// - Parameter target: A frame rate.
    /// - Returns: `true` if the method successfully configured the frame rate;
    /// otherwise `false`.
    func configureFrameRate(_ frameRate: Double) -> Bool {
        do { try lockForConfiguration() } catch {
            print("`AVCaptureDevice` wasn't unable to lock: \(error)")
            return false
        }

        // Release the configuration lock after returning from this method.
        defer { unlockForConfiguration() }

        // Sort the available frame rate ranges by descending `maxFrameRate`.
        let sortedRanges = activeFormat.videoSupportedFrameRateRanges.sorted {
            $0.maxFrameRate > $1.maxFrameRate
        }

        // Get the range with the highest `maxFrameRate`.
        guard let range = sortedRanges.first else {
            return false
        }

        // Ensure the target frame rate isn't below the range.
        guard frameRate >= range.minFrameRate else {
            return false
        }

        // Define the duration based on the target frame rate.
        let duration = CMTime(value: 1, timescale: CMTimeScale(frameRate))

        // If the target frame rate is within the range, use it as the minimum.
        let inRange = frameRate <= range.maxFrameRate
        activeVideoMinFrameDuration = inRange ? duration : range.minFrameDuration
        activeVideoMaxFrameDuration = range.maxFrameDuration

        return true
    }
}
