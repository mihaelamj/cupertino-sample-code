/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents command options to parse command line arguments.
*/

import ArgumentParser
import AVFoundation
import VideoToolbox

/// Command options that conform to the `AsyncParsableCommand` protocol of `swift-argument-parser`.
@main
struct CommandOptions: AsyncParsableCommand {
    /// The top-level usage statement for this app.
    static var configuration = CommandConfiguration(
        usage: """
            VTEncoderForConferencing <source-movie> [<options>]
            """)

    /// The source movie file from which to read video frames.
    @Argument(help: "The source movie file from which to read video frames.")
    var sourceMovie: String

    /// The destination movie target bit rate in bits per second.
    @Option(help: ArgumentHelp("The destination movie target bit rate in bits per second. (default: unset)", valueName: "n"))
    var bitrate: Int?

    /// Represents the codec types that this app supports.
    enum CodecType: String, CaseIterable, ExpressibleByArgument {
        case avc1, hvc1
    }

    /// The codec type enumeration to encode with.
    @Option(name: .customLong("codec"),
            help: ArgumentHelp("The codec fourCC to encode with.",
                               discussion: "Use one of \(CodecType.allCases.map(\.rawValue).description)", valueName: "s"))
    var codecType: CodecType = .avc1

    /// The destination movie width and height to store in an array, in that order.
    @Option(parsing: .upToNextOption,
            help: ArgumentHelp("The destination movie width and height.", valueName: "n n"))
    var dimensions: [Int] = [1280, 720]

    /// The maximum number of frames to encode.
    @Option(name: .customLong("frames"),
            help: ArgumentHelp("The max number of frames to encode. (default: all frames)", valueName: "n"))
    var frameCount: Int?

    /// The destination movie file to write output video frames to.
    @Option(name: .customLong("out"),
            help: ArgumentHelp("The destination movie file to write output video frames to.", valueName: "s"))
    var destMovie = "out.mov"

    /// Represents the pixel formats that this app supports.
    enum PixelFormatType: String, CaseIterable, ExpressibleByArgument {
        case bgra = "BGRA"
        case v420 = "420v"
    }

    /// The pixel format enumeration to encode with.
    @Option(name: .customLong("pixel-format"),
            help: ArgumentHelp("The pixel format to encode with.",
                               discussion: "Use one of \(PixelFormatType.allCases.map(\.rawValue).description)", valueName: "s"))
    var pixelFormatType: PixelFormatType = .v420

    /// Represents the preset types that this app supports.
    enum PresetType: String, CaseIterable, ExpressibleByArgument {
        case videoConferencing
    }

    /// The encode preset to encode with.
    @Option(name: .customLong("preset"),
            help: ArgumentHelp("The encode preset to encode with. (default: unset)",
                               discussion: "Use one of \(PresetType.allCases.map(\.rawValue).description)", valueName: "s"))
    var presetType: PresetType?

    /// Represents the codec profile types that this app supports.
    enum ProfileType: String, CaseIterable, ExpressibleByArgument {
        case main, main10, high
    }

    /// The target codec profile.
    @Option(name: .customLong("profile"),
            help: ArgumentHelp("The target codec profile. (default: unset)",
                               discussion: "Use one of \(ProfileType.allCases.map(\.rawValue).description) if codec supports it.", valueName: "s"))
    var profileType: ProfileType?

    /// A Boolean value that specifies whether to print noisy status.
    @Flag(help: "Print noisy status.")
    var verbose = false

    /// Validate command line options.
    mutating func validate() throws {
        if let bitrate {
            guard bitrate > 0 else {
                throw RuntimeError("The value '\(bitrate)' is invalid for '--bitrate'")
            }
        }

        guard dimensions.count == 2, dimensions[0] >= 64, dimensions[1] >= 64 else {
            throw RuntimeError("The value '\(dimensions)' is invalid for '--dimensions'")
        }

        if let frameCount {
            guard frameCount > 0 else {
                throw RuntimeError("The value '\(frameCount)' is invalid for '--frames'")
            }
        }
    }

    /// Entry point to use the parsed command line arguments to compress video.
    mutating func run() async throws {
        // Map `CodecType` enumeration to `CMVideoCodecType`.
        // Map `ProfileType` enumeration to (`CodecProfile` enumeration, profile name).
        let codec: CMVideoCodecType
        var profileTuple: (CodecProfile, String)?
        switch codecType {
        case .avc1:
            codec = kCMVideoCodecType_H264
            if let profileType {
                guard profileType != .main10 else {
                    throw RuntimeError("'\(codecType.rawValue)' doesn't support '\(profileType.rawValue)' profile.")
                }

                if profileType == .main {
                    profileTuple = (.h264Main, profileType.rawValue)
                } else if profileType == .high {
                    profileTuple = (.h264High, profileType.rawValue)
                }
            }
        case .hvc1:
            codec = kCMVideoCodecType_HEVC
            if let profileType {
                guard profileType != .high else {
                    throw RuntimeError("'\(codecType.rawValue)' doesn't support '\(profileType.rawValue)' profile.")
                }

                if profileType == .main {
                    profileTuple = (.hevcMain, profileType.rawValue)
                } else if profileType == .main10 {
                    profileTuple = (.hevcMain10, profileType.rawValue)
                }
            }
        }

        // Map `PresetType` enumeration to (`EncodePreset` enumeration, preset name).
        var presetTuple: (EncodePreset, String)?
        if let presetType {
            presetTuple = switch presetType {
            case .videoConferencing: (.videoConferencing, presetType.rawValue)
            }
        }

        // Map pixel format enumeration to `OSType`.
        let pixelFormat = switch pixelFormatType {
        case .v420: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        case .bgra: kCVPixelFormatType_32BGRA
        }

        // Update movie file extension if necessary, and get the movie file type.
        let dest = updateMoviePathIfNecessaryAndGetFileType(destMovie)
        let destMoviePath = dest.moviePath
        let destFileType = dest.fileType
        if destMoviePath == sourceMovie {
            throw RuntimeError("The source movie and the destination movie have the same name '\(sourceMovie)'.")
        }

        // Construct options with command line arguments or default values.
        // Use `Int.max` if `frameCount` isn't specified.
        let userOptions = Options(sourceMoviePath: sourceMovie,
                                  destMoviePath: destMoviePath,
                                  destFileType: destFileType,
                                  frameCount: frameCount ?? .max,
                                  destWidth: dimensions[0],
                                  destHeight: dimensions[1],
                                  destBitRate: bitrate,
                                  codec: codec,
                                  profileTuple: profileTuple,
                                  presetTuple: presetTuple,
                                  pixelFormat: pixelFormat,
                                  verbose: verbose)

        if verbose {
            print("""
                Application Parameters
                \(userOptions.description)

                """)
        }

        // Use the options structure to compress video.
        try await processVideoConferencing(options: userOptions)
    }
}
