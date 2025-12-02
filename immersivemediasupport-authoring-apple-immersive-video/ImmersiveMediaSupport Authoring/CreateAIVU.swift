/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Creates the necessary `ImmersiveMediaSupport` metadata needed to create Apple Immersive Video Universal files,
  and calls the writer to create the AIVU file from the provided inputs.
*/

import Foundation
import AVFoundation
import ImmersiveMediaSupport
import ArgumentParser // Available from Apple: https://github.com/apple/swift-argument-parser

@main
struct CreateAIVU: AsyncParsableCommand {
    @Option(name: [.short, .customLong("input")], help: "An Apple Immersive Video MV-HEVC video file without any necessary metadata.")
    var inputFile: String
    
    @Option(name: [.short, .customLong("aime")], help: "AIME file with the correct camera calibrations for the provided input file.")
    var aimeFile: String?
    
    @Option(name: [.short, .customLong("usdz")],
            help: "Optional USDZ file for camera calibration to use instead of an AIME file. (Must be used with --mask option).")
    var usdzFile: String?
    
    @Option(name: [.short, .customLong("mask")],
            help: "Optional dynamic mask JSON data for camera calibration to use instead of an AIME file. (Must be used with --usdz option).")
    var maskFile: String?
    
    @Option(name: [.short, .customLong("output")], help: "Output AIVU file with included ImmersiveMediaSupport metadata.")
    var outputFile: String
    
    private var customCreatedCalibrationId = "CustomCreatedCalibration"
    
    mutating func run() async throws {
        guard outputFile.lowercased().hasSuffix(".aivu") else {
            throw RuntimeError("Output file must end in .aivu")
        }
        
        print("Creating .aivu file")
        
        // Setup the `inputURL` and `outputURL`.
        let inputURL = URL(filePath: inputFile)
        let outputURL = URL(filePath: outputFile)

        // Create the `VenueDescriptor` for the AIVU file from the provided input options.
        let venueDescriptor = try await createVenueDescriptor()

        // Create a `PresentationDescriptor` for the AIVU file with some default commands.
        let presentationDescriptor = try await createPresentationDescriptor(with: venueDescriptor)

        print("Input: \(inputURL)")
        print("Output: \(outputURL)")
        
        if FileManager.default.fileExists(atPath: outputURL.path()) {
            print("Output file already exists, removing to rewrite output file.")
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        // Use the writer to create the AIVU output file.
        try await CreateAIVUWriter.create(from: inputURL, venue: venueDescriptor, presentation: presentationDescriptor, to: outputURL)
        
        // Validate the created AIVU file.
        let valid = try await AIVUValidator.validate(url: outputURL)
        guard valid else {
            throw RuntimeError("Invalid AIVU file created.")
        }
    }
    
    private func createVenueDescriptor() async throws -> VenueDescriptor {
        var venueDescriptor: VenueDescriptor? = nil
        if let aimeFile {
            // Define the `VenueDescriptor` with the provided Apple Immersive Media Embedded file.
            let aimeURL = URL(filePath: aimeFile)
            venueDescriptor = try await VenueDescriptor(aimeURL: aimeURL)
        } else if let usdzFile, let maskFile {
            // Define the `ImmersiveCameraCalibration` with the USDZ file and Mask file.
            let usdzURL = URL(filePath: usdzFile)
            let usdzData = try Data(contentsOf: usdzURL)
            let maskData = try Data(contentsOf: URL(filePath: maskFile))
            
            let calibrationName = usdzURL.lastPathComponent
            let mask = try JSONDecoder().decode(ImmersiveDynamicMask.self, from: maskData)
            let usdzMeshCalibration = ImmersiveCameraMeshCalibration(name: calibrationName, usdzData: usdzData)
            let cameraCalibration = ImmersiveCameraCalibration(name: calibrationName, type: .usdzMesh(usdzMeshCalibration), mask: .dynamic(mask))
            
            // Create the `ImmersiveCamera`.
            let camera = ImmersiveCamera(id: customCreatedCalibrationId, calibration: cameraCalibration)
            
            // Create `VenueDescriptor` and add the custom created camera.
            venueDescriptor = VenueDescriptor()
            try await venueDescriptor?.addCamera(camera)
        }
        
        guard let venueDescriptor else {
            throw RuntimeError(
                "VenueDescriptor not created from the provided input files. Please include a valid --aime file, or a valid --usdz and --mask file."
            )
        }
        
        return venueDescriptor
    }
    
    private func createPresentationDescriptor(with venueDescriptor: VenueDescriptor) async throws -> PresentationDescriptor {
        // Create a `fadeIn` command of five seconds at the start of the video, and set the unique identifier of the command.
        let fadeIn = FadeCommand(id: 1, time: .zero, duration: CMTime(seconds: 5, preferredTimescale: 1), direction: .in, color: [0.0, 0.0, 0.0])
        var presentationDescriptor = PresentationDescriptor(commands: [PresentationCommand.fade(fadeIn)])

        // If the `VenueDescriptor` has a camera whose ID matches the `customCreatedCalibrationId`,
        // create a `SetCameraCommand` at the beginning to use that camera calibration, and set the unique identifier of the command.
        if await venueDescriptor.cameras.contains(where: { $0.id == customCreatedCalibrationId }) {
            let setCamera = SetCameraCommand(id: 2, time: .zero, cameraID: customCreatedCalibrationId)
            presentationDescriptor.commands.append(PresentationCommand.setCamera(setCamera))
        } else {
            // Apple Immersive Video expects a `SetCameraCommand` to know which camera to use from the `VenueDescriptor` data,
            // and set the unique identifier of the command.
            let cameraId = await venueDescriptor.cameras.last?.id ?? "CAMERA1"
            let setCamera = SetCameraCommand(id: 2, time: .zero, cameraID: cameraId)
            presentationDescriptor.commands.append(PresentationCommand.setCamera(setCamera))
        }
        
        return presentationDescriptor
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}
