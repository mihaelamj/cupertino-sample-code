/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Helper file for Spatial Audio command-line interface.
*/

import Cinematic

struct SpatialUtility {

    static let actions = [
        "preview",
        "bake",
        "process"
    ]

    // Help string corresponding to each action.
    static let help = [
        "Preview the Audio Mix params applied to the input file, using AVPlayer.",
        "Use AVAssetReader and Writer to apply the Audio Mix params to the input file. Include a stereo compatibility track.",
        "Use AUAudioMix to apply the Audio Mix params to the input file. Render to a discrete channel layout."
    ]

    // Combines each action with its respective help string.
    static let helpStr = {
        var helpStr = ""
        for (action, hlp) in zip(actions, help) {
            helpStr += "\(action) -> \(hlp)\n\n"
        }
        return helpStr
    }
    
    // Maps the input style string to its `CNSpatialAudioRenderingStyle`.
    static let renderingStylesMap = [
        "cinematic": CNSpatialAudioRenderingStyle.cinematic,
        "studio": CNSpatialAudioRenderingStyle.studio,
        "inFrame": CNSpatialAudioRenderingStyle.inFrame,
        "cinematicBackgroundStem": CNSpatialAudioRenderingStyle.cinematicBackgroundStem,
        "cinematicForegroundStem": CNSpatialAudioRenderingStyle.cinematicForegroundStem,
        "inFrameForegroundStem": CNSpatialAudioRenderingStyle.inFrameForegroundStem,
        "standard": CNSpatialAudioRenderingStyle.standard,
        "studioBackgroundStem": CNSpatialAudioRenderingStyle.studioBackgroundStem,
        "inFrameBackgroundStem": CNSpatialAudioRenderingStyle.inFrameBackgroundStem
    ]
    
    // Maps the input audio output layout string to its AVAudioChannelLayout.
    static let outputLayoutMap = [
        "mono": AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono),
        "stereo": AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Stereo),
        "surround": AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_MPEG_5_1_A),
        "atmos": AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Atmos_7_1_4)
    ]
    
    static let outputChannelMap = [
        "mono": 1,
        "stereo": 2,
        "surround": 6,
        "atmos": 12
    ] as [String: UInt32]
    
    // Checks that the specified style is in the supported list of
    // `CNSpatialAudioRenderingStyles`.
    @Sendable static func verifyCNSpatialAudioRenderingStyle(style: String) -> String {
        guard renderingStylesMap[style] != nil else {
            print("Unsupported rendering style \(style)")
            print("Supported styles -> \(renderingStylesMap.keys.joined(separator: ", "))")
            fatalError()
        }
        return style
    }
    
    // Checks that the specified audio format is in the supported list of
    // `AVAudioChannelLayouts`.
    @Sendable static func verifyAudioOutput(layout: String) -> String {
        guard outputLayoutMap[layout] != nil else {
            print("Unsupported audio output \(layout)")
            print("Supported layouts -> \(outputLayoutMap.keys.joined(separator: ", "))")
            fatalError()
        }
        return layout
    }
    
    static func deleteFiles(_ fileURLs: [URL]) {
        for fileURL in fileURLs {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(atPath: fileURL.path)
                } catch {
                    print("Could not remove file at url: \(String(describing: fileURL))")
                }
            }
        }
    }
    
    struct PreviewInput {
        let inputFile: URL
        let intensity: Float
        let style: String
        let duration: Float
    }
    
    struct BakeInput {
        let inputFile: URL
        let outputFile: URL
        let intensity: Float
        let style: String
        let includeVideo: Bool
    }
    
    struct ProcessInput {
        let inputFile: URL
        let outputFile: URL
        let intensity: Float
        let style: String
        let audioOutputFormat: String
        let includeVideo: Bool
    }
    
    struct SetupAudioMixInput {
        let inputASBD: AudioStreamBasicDescription
        let outputASBD: AudioStreamBasicDescription
        let metadata: CFData
        let intensity: Float
        let style: CNSpatialAudioRenderingStyle
    }
    
    struct RuntimeError: LocalizedError {
        let description: String

        init(_ description: String) {
            self.description = description
        }

        var errorDescription: String? {
            description
        }
    }
}
