/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A helper type that builds a video composition.
*/

import AVFoundation

struct VideoCompositionBuilder {

    private let asset: AVAsset
    private let compositorType: CompositorType

    /// Creates a video composition builder.
    ///
    /// - Parameters:
    ///   - asset: The asset for which to build a video composition.
    ///   - compositorType: The compositor type to use.
    init(asset: AVAsset, compositorType: CompositorType) {
        self.asset = asset
        self.compositorType = compositorType
    }

    /// Builds a video composition object.
    func build() async throws -> AVVideoComposition {

        // Create the video composition configuration object for the asset.
        var configuration = try await AVVideoComposition.Configuration(for: asset)
        // Specify the compositor class to use, either `MonoOutputCompositor` or `StereoOutputCompositor`.
        configuration.customVideoCompositorClass = compositorType.compositorClass

        // Determine the color settings to apply to the video composition configuration.
        let formatDescription = try await formatDescription
        configuration.colorYCbCrMatrix = formatDescription.extensions[kCVImageBufferYCbCrMatrixKey] as? String
        configuration.colorPrimaries = formatDescription.extensions[kCVImageBufferColorPrimariesKey] as? String
        configuration.colorTransferFunction = formatDescription.extensions[kCVImageBufferTransferFunctionKey] as? String
        configuration.perFrameHDRDisplayMetadataPolicy = .generate

        // Determine the projection to apply to the presented video frames.
        let projectionTag = try await projectionTypeTag

        if compositorType.outputsStereo {
            // Wrap the instructions in the app's custom instruction type.
            configuration.instructions = configuration.instructions.compactMap {
                SpatialVideoCompositionInstruction(
                    instruction: $0,
                    spatialConfiguration: configuration.spatialVideoConfigurations.first,
                    projectionTag: projectionTag
                )
            }
            configuration.outputBufferDescription = [
                [.stereoView(.leftEye), projectionTag, .mediaType(.video)],
                [.stereoView(.rightEye), projectionTag, .mediaType(.video)]
            ]
        } else {
            configuration.outputBufferDescription = nil
            configuration.spatialVideoConfigurations = []
        }

        return AVVideoComposition(configuration: configuration)
    }

    /// The asset's video track.
    ///
    /// Accessing this property throws a fatal error if no video track is found in the asset.
    private var videoTrack: AVAssetTrack {
        get async throws {
            guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                fatalError("No video track found in asset.")
            }
            return videoTrack
        }
    }

    /// The format description for the asset's video track.
    ///
    /// Accessing this property throws a fatal error if no format descriptions are found in the asset.
    private var formatDescription: CMFormatDescription {
        get async throws {
            guard let formatDescription = try await videoTrack.load(.formatDescriptions).first else {
                fatalError("No format description found in video track")
            }
            return formatDescription
        }
    }

    /// The projection type tag for the asset's video track.
    private var projectionTypeTag: CMTag {
        get async throws {
            let projectionKindString = try await formatDescription.extensions[kCMFormatDescriptionExtension_ProjectionKind] as? String
            let projectionTag: CMTag
            switch projectionKindString {
            case kCMFormatDescriptionProjectionKind_Rectilinear as CFString:
                projectionTag = .projectionType(.rectangular)
            case kCMFormatDescriptionProjectionKind_Equirectangular as CFString:
                projectionTag = .projectionType(.equirectangular)
            case kCMFormatDescriptionProjectionKind_HalfEquirectangular as CFString:
                projectionTag = .projectionType(.halfEquirectangular)
            case kCMFormatDescriptionProjectionKind_ParametricImmersive as CFString:
                projectionTag = .projectionType(.parametricImmersive)
            case kCMFormatDescriptionProjectionKind_AppleImmersiveVideo as CFString:
                projectionTag = .projectionType(.fisheye)
            default:
                projectionTag = .projectionType(.rectangular)
            }
            return projectionTag
        }
    }
}

// Custom video composition instruction class.
class SpatialVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {

    private let wrappedInstruction: any AVVideoCompositionInstructionProtocol

    let spatialConfiguration: AVSpatialVideoConfiguration?
    let projectionTag: CMTag?

    init(instruction: any AVVideoCompositionInstructionProtocol, spatialConfiguration: AVSpatialVideoConfiguration?, projectionTag: CMTag?) {
        wrappedInstruction = instruction
        self.spatialConfiguration = spatialConfiguration
        self.projectionTag = projectionTag
    }

    var timeRange: CMTimeRange {
        wrappedInstruction.timeRange
    }

    var enablePostProcessing: Bool {
        wrappedInstruction.enablePostProcessing
    }

    var containsTweening: Bool {
        wrappedInstruction.containsTweening
    }

    var requiredSourceTrackIDs: [NSValue]? {
        wrappedInstruction.requiredSourceTrackIDs
    }

    var passthroughTrackID: CMPersistentTrackID {
        wrappedInstruction.passthroughTrackID
    }
}

enum CompositorType: String, CaseIterable, Identifiable {
    case none
    case monoOut
    case stereoOut
    var id: Self { self }

    var compositorClass: AVVideoCompositing.Type? {
        switch self {
        case .none:
            return nil
        case .monoOut:
            return MonoOutputCompositor.self
        case .stereoOut:
            return StereoOutputCompositor.self
        }
    }

    var outputsStereo: Bool {
        switch self {
        case .none:
            return false
        case .monoOut:
            return false
        case .stereoOut:
            return true
        }
    }
}

extension AVVideoComposition {
    var outputsStereo: Bool {
        outputBufferDescription?.count == 2
    }
}
