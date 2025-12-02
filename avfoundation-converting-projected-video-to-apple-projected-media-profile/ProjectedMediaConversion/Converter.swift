/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Reads source video input and performs conversion to a QuickTime video file that conforms to the Apple Projected Media Profile delivery specification.
*/

import Foundation
@preconcurrency import AVFoundation
import CoreMedia
import VideoToolbox

// MV-HEVC properties only necessary when encoding stereo video as MV-HEVC

/// The first video layer ID must always be 0 (representing the hero eye) and the other layer ID will be selected as 1 here.
/// - Tag: VideoLayers
let MVHEVCVideoLayerIDs = [0, 1]

/// For simplicity, choose view IDs that match the layer IDs.
let MVHEVCViewIDs = [0, 1]

/// The first element in this array is the view ID of the left eye.
/// In combination with the previously defined view IDs and layers IDs the left eye will be stored in layer 0.
let MVHEVCLeftAndRightViewIDs = [0, 1]

/// Transcode to MV-HEVC or HEVC as appropriate, convert frame-packed if necessary
final class APMPConverter: Sendable {
	let sourceVideoFrameSize: CGSize
	
	let reader: AVAssetReader
	let sourceVideoTrack: AVAssetReaderTrackOutput
	let sourceVideoTrackProvider: AVAssetReaderOutput.Provider<CMReadySampleBuffer<CMSampleBuffer.DynamicContent>>
	
	/// Loads a video to read for conversion.
	/// - Parameter url: A URL to a source video file
	/// - Tag: ReadInputVideo
	init(from url: URL) async throws {
		let asset = AVURLAsset(url: url)
		reader = try AVAssetReader(asset: asset)
		
		// Get the video track.
		guard let videoTrack = try await asset.loadTracks(withMediaCharacteristic: .visual).first else {
			fatalError("Error loading side-by-side video input")
		}
		
		sourceVideoFrameSize = try await videoTrack.load(.naturalSize)
		
		let readerSettings: [String: Any] = [
			kCVPixelBufferIOSurfacePropertiesKey as String: [String: String]()
		]
		sourceVideoTrack = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerSettings)
		
		sourceVideoTrackProvider = reader.outputProvider(for: sourceVideoTrack)
		
		do {
			try reader.start()
		} catch {
			fatalError(reader.error?.localizedDescription ?? "Unknown error during track read start")
		}
	}
	
	/// Transcodes source video to delivery spec version of APMP
	/// - Parameter output: The output URL to write the video file to.
	/// - Parameter projectedMediaMetadata: APMP metadata to add to the output file.
	/// - Tag: TranscodeVideo
	func convertToAPMP(output videoOutputURL: URL, projectedMediaMetadata: ProjectedMediaMetadata) async throws {
		var verticalScale = 1.0
		var horizontalScale = 1.0
		var isSideBySide = false
		var isFramePacked = false
		if let viewPackingKind = projectedMediaMetadata.viewPackingKind {
			isFramePacked = true
			if viewPackingKind.caseInsensitiveCompare("SideBySide") == .orderedSame {
				horizontalScale = 2.0
				isSideBySide = true
			} else if viewPackingKind.caseInsensitiveCompare("OverUnder") == .orderedSame {
				verticalScale = 2.0
			}
		}
		let eyeFrameSize = CGSize(width: sourceVideoFrameSize.width / horizontalScale, height: sourceVideoFrameSize.height / verticalScale)

		let assetWriter = try AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mov)
		
		let stereoCompressionProperties: [CFString: Any] = [
			kVTCompressionPropertyKey_MVHEVCVideoLayerIDs: MVHEVCVideoLayerIDs,
			kVTCompressionPropertyKey_MVHEVCViewIDs: MVHEVCViewIDs,
			kVTCompressionPropertyKey_MVHEVCLeftAndRightViewIDs: MVHEVCLeftAndRightViewIDs,
			kVTCompressionPropertyKey_HasLeftStereoEyeView: true,
			kVTCompressionPropertyKey_HasRightStereoEyeView: true
		]
		var compressionProperties: [CFString: Any] = isFramePacked ? stereoCompressionProperties : [:]
		
		let projectionKind = projectedMediaMetadata.projectionKind
		if projectionKind.caseInsensitiveCompare("Equirectangular") == .orderedSame {
			compressionProperties[kVTCompressionPropertyKey_ProjectionKind] = kCMFormatDescriptionProjectionKind_Equirectangular
		} else if projectionKind.caseInsensitiveCompare("HalfEquirectangular") == .orderedSame {
			compressionProperties[kVTCompressionPropertyKey_ProjectionKind] = kCMFormatDescriptionProjectionKind_HalfEquirectangular
		} else {
			fatalError("Unrecognized projection kind for projected media")
		}
		
		if let baselineInMillimeters = projectedMediaMetadata.baselineInMillimeters {
			let baselineInMicrometers = UInt32(1000.0 * baselineInMillimeters)
			compressionProperties[kVTCompressionPropertyKey_StereoCameraBaseline] = baselineInMicrometers
		}
		
		if let horizontalFOV = projectedMediaMetadata.horizontalFOV {
			let encodedHorizontalFOV = UInt32(1000.0 * horizontalFOV)
			compressionProperties[kVTCompressionPropertyKey_HorizontalFieldOfView] = encodedHorizontalFOV
		}
		
		let outputSettings: [String: Any] = [
			AVVideoCodecKey: AVVideoCodecType.hevc,
			AVVideoWidthKey: eyeFrameSize.width,
			AVVideoHeightKey: eyeFrameSize.height,
			AVVideoCompressionPropertiesKey: compressionProperties
		]
		
		guard assetWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
			fatalError("Error applying output settings")
		}
		
		let frameInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
		let sourcePixelAttributes = CVPixelBufferCreationAttributes(
			pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
			size: .init(self.sourceVideoFrameSize))
		
		var taggedBufferInputReceiver: AVAssetWriterInput.TaggedPixelBufferGroupReceiver? = nil
		var bufferInputReceiver: AVAssetWriterInput.PixelBufferReceiver? = nil
		if isFramePacked {
			taggedBufferInputReceiver = assetWriter.inputTaggedPixelBufferGroupReceiver(for: frameInput, pixelBufferAttributes: sourcePixelAttributes)
		} else {
			bufferInputReceiver = assetWriter.inputPixelBufferReceiver(for: frameInput, pixelBufferAttributes: sourcePixelAttributes)
		}
		
		try assetWriter.start()
		assetWriter.startSession(atSourceTime: CMTime.zero)
		
		let framePacked = isFramePacked
		if framePacked { // stereoscopic output
			let sideBySide = isSideBySide
			guard let taggedBufferInputReceiver else {
				fatalError("No tagged buffer input receiver")
			}
			var session: VTPixelTransferSession? = nil
			guard VTPixelTransferSessionCreate(allocator: kCFAllocatorDefault, pixelTransferSessionOut: &session) == noErr, let session else {
				fatalError("Failed to create pixel transfer")
			}
			guard let pixelBufferPool = taggedBufferInputReceiver.pixelBufferPool else {
				fatalError("Failed to retrieve existing pixel buffer pool")
			}
			
			// Handling all available frames within the closure improves performance.
			while let sampleBuffer = try await sourceVideoTrackProvider.next() {
				let newPTS = sampleBuffer.outputPresentationTimeStamp
				let taggedBuffers = try convertFrame(from: sampleBuffer, packing: sideBySide, with: pixelBufferPool, in: session)
				try await taggedBufferInputReceiver.append(taggedBuffers, with: newPTS)
			}
		} else { // monoscopic output
			guard let bufferInputReceiver else {
				fatalError("No buffer input receiver")
			}
			
			while let sampleBuffer = try await sourceVideoTrackProvider.next() {
				guard case .pixelBuffer(let pixelBuffer) = sampleBuffer.content else {
					fatalError("Failed to get pixel buffer")
				}
				let newPTS = sampleBuffer.outputPresentationTimeStamp
				try await bufferInputReceiver.append(pixelBuffer, with: newPTS)
			}
		}
		await assetWriter.finishWriting()
	}

	func convertFrame(from sampleBuffer: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>, packing sideBySide: Bool, with pixelBufferPool: CVMutablePixelBuffer.Pool, in session: VTPixelTransferSession) throws -> [CMTaggedDynamicBuffer] {
		// Output contains two tagged buffers, with the left eye frame first.
		var taggedBuffers: [CMTaggedDynamicBuffer] = []
		let eyes: [CMStereoViewComponents] = [.leftEye, .rightEye]
		var eyeFrameSize: CGSize
		if sideBySide {
			eyeFrameSize = CGSize(width: sourceVideoFrameSize.width / 2, height: sourceVideoFrameSize.height)
		} else {
			eyeFrameSize = CGSize(width: sourceVideoFrameSize.width, height: sourceVideoFrameSize.height / 2)
		}
		
		try sampleBuffer.withUnsafeSampleBuffer { cmSampleBuffer in
			guard let imageBuffer = CMSampleBufferGetImageBuffer(cmSampleBuffer) else {
				fatalError("Failed to load source samples as an image buffer")
			}
			
			for (layerID, eye) in zip(MVHEVCVideoLayerIDs, eyes) {
				let pixelBuffer = try pixelBufferPool.makeMutablePixelBuffer()
				
				// Crop the transfer region to the current eye.
				var apertureHorizontalOffset: CGFloat
				var apertureVerticalOffset: CGFloat
				if sideBySide {
					apertureHorizontalOffset = -(eyeFrameSize.width / 2) + CGFloat(layerID) * eyeFrameSize.width
					apertureVerticalOffset = 0
				} else {
					apertureHorizontalOffset = 0
					apertureVerticalOffset = -(eyeFrameSize.height / 2) + CGFloat(layerID) * eyeFrameSize.height
				}
				let cropRectDict = [
					kCVImageBufferCleanApertureHorizontalOffsetKey: apertureHorizontalOffset,
					kCVImageBufferCleanApertureVerticalOffsetKey: apertureVerticalOffset,
					kCVImageBufferCleanApertureWidthKey: eyeFrameSize.width,
					kCVImageBufferCleanApertureHeightKey: eyeFrameSize.height
				]
				CVBufferSetAttachment(imageBuffer, kCVImageBufferCleanApertureKey, cropRectDict as CFDictionary, CVAttachmentMode.shouldPropagate)
				VTSessionSetProperty(session, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_CropSourceToCleanAperture)
				
				// Transfer the image to the pixel buffer.
				pixelBuffer.withUnsafeBuffer { cvPixelBuffer in
					guard VTPixelTransferSessionTransferImage(session, from: imageBuffer, to: cvPixelBuffer) == noErr else {
						fatalError("Error during pixel transfer session for layer \(layerID)")
					}
				}
				
				// Create and append a tagged buffer for this eye.
				let tags: [CMTag] = [.videoLayerID(Int64(layerID)), .stereoView(eye)]
				taggedBuffers.append(.init(tags: tags, content: .pixelBuffer(.init(pixelBuffer))))
			}
		}
		
		return taggedBuffers
	}
}

