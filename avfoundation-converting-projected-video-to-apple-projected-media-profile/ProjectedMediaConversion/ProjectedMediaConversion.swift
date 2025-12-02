/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Processes command-line arguments and converts source movie assets into projected media profile for distribution and delivery.
*/

import Foundation
import ArgumentParser // Available from Apple: https://github.com/apple/swift-argument-parser

@main
struct ProjectedMediaConversion: AsyncParsableCommand {

    @Argument(help: "The source video file to convert.")
    var sourceVideoPath: String

    @Option(
        name: [.customShort("b"), .customLong("baseline")],
        help: "The baseline (distance between the centers of two cameras), in millimeters."
    )
    var baselineInMillimeters: Double? = nil

    @Option(
        name: [.customShort("f"), .customLong("fov")],
        help: "The horizontal field of view of each camera, in degrees."
    )
    var horizontalFOV: Double? = nil

	@Option(
		name: [.customShort("p"), .customLong("projectionKind")],
		help: "The projectionKind for projected media."
	)
	var projectionKind: String? = nil
	
	@Option(
		name: [.customShort("v"), .customLong("viewPackingKind")],
		help: "The viewPackingKind representing the frame-packed configuration for the source file."
	)
	var viewPackingKind: String? = nil
	
	@Flag(
		name: [.customShort("a"), .customLong("autoDetect")],
		help: "Attempt to automatically detect projection and view-packing parameters from source file."
	)
	var autoDetect = false
	
    mutating func run() async throws {

		let projectedMediaMetadata: ProjectedMediaMetadata
        let outputVideoType: String

		let inputURL = URL(fileURLWithPath: sourceVideoPath)

		if autoDetect {
			let classifier = try await ProjectedMediaClassifier(from: inputURL)
			projectionKind = classifier.projectionKind
			viewPackingKind = classifier.viewPackingKind
		}

		guard let projectionKind else {
			throw ConversionError("Missing projected kind metadata")
		}
		projectedMediaMetadata = ProjectedMediaMetadata(
			projectionKind: projectionKind,
			viewPackingKind: viewPackingKind,
			baselineInMillimeters: baselineInMillimeters,
			horizontalFOV: horizontalFOV
		)
		outputVideoType = "apmp"

        // Determine an appropriate output file URL.
        let converter = try await APMPConverter(from: inputURL)
        let outputFileName = inputURL.deletingPathExtension().lastPathComponent + "_\(outputVideoType).mov"
        let outputURL = inputURL.deletingLastPathComponent().appendingPathComponent(outputFileName)

        // Delete a previous output file with the same name if one exists.
        if FileManager.default.fileExists(atPath: outputURL.path()) {
            try FileManager.default.removeItem(at: outputURL)
        }

        // Perform the video conversion.
		try await converter.convertToAPMP(output: outputURL, projectedMediaMetadata: projectedMediaMetadata)
        print("\(outputVideoType) video written to \(outputURL).")

    }

}

struct ProjectedMediaMetadata {
	var projectionKind: String
	var viewPackingKind: String?		 // optional, only for frame-packed source
	var baselineInMillimeters: Double?   // optional, only if stereoscopic
	var horizontalFOV: Double?           // optional
}

struct ConversionError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) {
        self.description = description
    }
}
