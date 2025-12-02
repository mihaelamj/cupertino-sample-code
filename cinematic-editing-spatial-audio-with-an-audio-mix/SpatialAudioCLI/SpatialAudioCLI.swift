/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Command-line tool for processing files with the Audio Mix effect.
*/

import Foundation
import ArgumentParser
import Cinematic

@main
struct SpatialAudioCLI: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
            abstract: """
            Use Audio Mix with spatial audio assets.
            """,
            usage: """
                preview <input-file> [--duration <duration>] [--intensity <intensity>] [--style <style>]
                bake <input-file> [--intensity <intensity>] [--style <style>] [--output <file>] [--delete] [--include-video]
                process <input-file> "" + [--audio-output-format <audio-output-format>]
                """
            )
    
    // Required action argument (preview, bake, process).
    @Argument(help: .init(SpatialUtility.helpStr()))
    var action: String

	@Argument(help: "input file", transform: URL.init(fileURLWithPath:))
    var inputFile: URL
    
    @Option(help: "preview duration (seconds)")
    var duration: Float = 5.0
    
    @Option(help: "effect intensity")
    var intensity: Float = 0.5
    
    @Option(help: "rendering style, supported styles -> \(SpatialUtility.renderingStylesMap.keys.joined(separator: ", "))",
            transform: SpatialUtility.verifyCNSpatialAudioRenderingStyle(style:))
    var style: String = "standard"

    @Option(name: [.short, .customLong("output")], help: "output file", transform: URL.init(fileURLWithPath:))
    var outputFile: URL? = nil
    
    @Option(name: .shortAndLong, help: "audio output, supported formats -> \(SpatialUtility.outputLayoutMap.keys.joined(separator: ", "))",
            transform: SpatialUtility.verifyAudioOutput(layout:))
    var audioOutputFormat: String = "stereo"
    
    @Flag(help: "delete existing output file")
    var delete = false
    
    @Flag(help: "include (unprocessed) video")
    var includeVideo = false

    // Validate action and input file before running.
    mutating func validate() throws {
        
        guard SpatialUtility.actions.firstIndex(of: action) != nil else {
            throw ValidationError("Unsupported action \(action). Supported actions:\n\(SpatialUtility.helpStr())")
        }
        
        guard FileManager.default.fileExists(atPath: inputFile.path) else {
            throw ValidationError("Input file does not exist.")
        }
        
        guard inputFile != outputFile else {
            throw ValidationError("Please specify a different output filename.")
        }
    }
    
    // The main controller of the CLI.
	mutating func run() async throws {
        
        // Ensure that the input file has proper Spatial Audio.
        guard await CNAssetSpatialAudioInfo.assetContainsSpatialAudio(asset: AVURLAsset(url: inputFile)) else {
            throw ValidationError("Cannot read spatial audio from input file.")
        }
        
        // Delete pre-existing output file, if specified.
        if delete && (outputFile != nil) {
            SpatialUtility.deleteFiles([outputFile!])
        }
                
		if action == "preview" {
            let previewInput = SpatialUtility.PreviewInput(inputFile: inputFile,
                                                           intensity: intensity,
                                                           style: style,
                                                           duration: duration)
            try await Actions.preview(previewInput)
			
        } else if action == "bake" {
            guard let outputFile = outputFile else {
                throw ValidationError("Output file must be specified")
            }
            let bakeInput = SpatialUtility.BakeInput(inputFile: inputFile,
                                                        outputFile: outputFile,
                                                        intensity: intensity,
                                                        style: style,
                                                        includeVideo: includeVideo)
            try await Actions.bake(bakeInput)
            
        } else if action == "process" {
            guard let outputFile = outputFile else {
                throw ValidationError("Output file must be specified")
            }
            let processInput = SpatialUtility.ProcessInput(inputFile: inputFile,
                                                           outputFile: outputFile,
                                                           intensity: intensity,
                                                           style: style,
                                                           audioOutputFormat: audioOutputFormat,
                                                           includeVideo: includeVideo)
            try await Actions.process(processInput)
            
        }
	}
}
