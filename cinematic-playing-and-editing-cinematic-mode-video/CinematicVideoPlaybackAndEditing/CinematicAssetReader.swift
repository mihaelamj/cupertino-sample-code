/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that reads sample buffers from a Cinematic mode video.
*/

import CoreMedia
import AVFoundation
import Cinematic
import OSLog

struct CinematicAssetSampleBuffer {
    let imageBuffer: CVPixelBuffer?
    let disparityBuffer: CVPixelBuffer?
    let metadataBuffer: CMSampleBuffer?
    let presentationTimeStamp: CMTime?
    init(imageBuffer: CVPixelBuffer? = nil,
         disparityBuffer: CVPixelBuffer? = nil,
         metadataBuffer: CMSampleBuffer? = nil,
         presentationTimeStamp: CMTime? = nil) {
        self.imageBuffer = imageBuffer
        self.disparityBuffer = disparityBuffer
        self.metadataBuffer = metadataBuffer
        self.presentationTimeStamp = presentationTimeStamp
    }
}

// The asset reader for helping object tracking.
struct CinematicAssetReader {
    let avAssetReader: AVAssetReader
    let avAssetReaderVideoTrackOutput: AVAssetReaderTrackOutput
    let avAssetReaderDisparityTrackOutput: AVAssetReaderTrackOutput
    let avAssetReaderMetadataTrackOutput: AVAssetReaderTrackOutput

    init(cinematicAssetData: CinematicAssetData) {
        do {
            avAssetReader = try AVAssetReader(asset: cinematicAssetData.avAsset)
            let videoOutputSettings: [String: Any] =
            [String(kCVPixelBufferPixelFormatTypeKey): CNRenderingSession.sourcePixelFormatTypes,
             String(kCVPixelBufferIOSurfacePropertiesKey): [String: Any]()]
            let disparityOutputSettings: [String: Any] =
            [String(kCVPixelBufferPixelFormatTypeKey): [kCVPixelFormatType_DisparityFloat16]]
            avAssetReaderVideoTrackOutput =
            AVAssetReaderTrackOutput(track:
                                    cinematicAssetData.assetInfo.cinematicVideoTrack,
                                    outputSettings: videoOutputSettings)
            avAssetReaderVideoTrackOutput.alwaysCopiesSampleData = false
            avAssetReader.add(avAssetReaderVideoTrackOutput)
            avAssetReaderDisparityTrackOutput = AVAssetReaderTrackOutput(track:
                            cinematicAssetData.assetInfo.cinematicDisparityTrack,
                            outputSettings: disparityOutputSettings)
            avAssetReaderDisparityTrackOutput.alwaysCopiesSampleData = false
            avAssetReader.add(avAssetReaderDisparityTrackOutput)
            avAssetReaderMetadataTrackOutput = AVAssetReaderTrackOutput(track:
                                        cinematicAssetData.assetInfo.cinematicMetadataTrack,
                                        outputSettings: nil)
            avAssetReaderMetadataTrackOutput.alwaysCopiesSampleData = false
            avAssetReader.add(avAssetReaderMetadataTrackOutput)
        } catch {
            fatalError("Failed to read cinematic asset")
        }
    }

    func setupForReading(timeRange: CMTimeRange) {
        avAssetReader.timeRange = timeRange
        
        let startedReading = avAssetReader.startReading()
        
        guard startedReading else { fatalError("Couldn't start reading") }
    }

    func cancelReading() {
        avAssetReader.cancelReading()
    }

    func getNextSampleBuffer() -> CinematicAssetSampleBuffer {
        let sourceSampleBuffer = avAssetReaderVideoTrackOutput.copyNextSampleBuffer()
        let disparitySampleBuffer =
        avAssetReaderDisparityTrackOutput.copyNextSampleBuffer()
        var sampleBuffer = avAssetReaderMetadataTrackOutput.copyNextSampleBuffer()
        if sampleBuffer != nil {
            if sampleBuffer?.numSamples == 0 {
                sampleBuffer = avAssetReaderMetadataTrackOutput.copyNextSampleBuffer()
            }
        }
        let metadataSampleBuffer = sampleBuffer
        if sourceSampleBuffer != nil
            && disparitySampleBuffer != nil
            && metadataSampleBuffer != nil {
            return CinematicAssetSampleBuffer(
                imageBuffer: sourceSampleBuffer?.imageBuffer,
                disparityBuffer: disparitySampleBuffer?.imageBuffer,
                metadataBuffer: metadataSampleBuffer,
                presentationTimeStamp: sourceSampleBuffer?.presentationTimeStamp)
        }
        return CinematicAssetSampleBuffer()
    }
}
