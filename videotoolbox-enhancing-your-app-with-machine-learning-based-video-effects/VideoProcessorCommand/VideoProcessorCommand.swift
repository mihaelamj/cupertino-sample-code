/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements a command line interface for `VideoProcessor`.
*/

import Foundation
import ArgumentParser
import AVFoundation
import OSLog
import AppKit

let logger = Logger()

@main
struct ProcessVideoEffect: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "processVideoEffect",
        abstract: "Apply video effect to the input file, writing results to the output file.",
        subcommands: [MotionBlur.self, FrateRateConversion.self])
}

extension ProcessVideoEffect {

    struct MotionBlur: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "motionBlur",
            abstract: "Apply a motion blur effect to the input file.",
            version: "1.0",
            aliases: ["mb"])

        @Option(name: [.short, .customLong("input")],
                 transform: URL.init(fileURLWithPath:))
        var inputURL: URL

        @Option(name: [.short, .customLong("output")],
                 transform: URL.init(fileURLWithPath:))
        var outputURL: URL

        @Argument(help: ArgumentHelp(
            "Motion blur strength between 1 - 100",
            valueName: "strength"))
        var motionBlurStrength = 50

        mutating func validate() throws {
            guard (1...100).contains(motionBlurStrength) else {
                throw ValidationError("The motion blur strength must be between 1 and 100")
            }
        }
    }
}

extension ProcessVideoEffect {

    struct FrateRateConversion: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "frameRateConversion",
            abstract: "Apply frame rate conversion to the input file.",
            version: "1.0",
            aliases: ["frc"])

        @Option(name: [.short, .customLong("input")],
                 transform: URL.init(fileURLWithPath:))
        var inputURL: URL

        @Option(name: [.short, .customLong("output")],
                 transform: URL.init(fileURLWithPath:))
        var outputURL: URL

        @Argument(help: ArgumentHelp(
            "Frame rate multiplier between 2 - 8",
            valueName: "multiplier"))
        var frameRateMultiplier = 4

        mutating func validate() throws {
            guard (2...8).contains(frameRateMultiplier) else {
                throw ValidationError("Frame rate multiplier must be between 2 - 8")
            }
        }

    }
}

extension ProcessVideoEffect {

    struct TemporalNoiseFilter: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "temporalNoiseFilter",
            abstract: "Apply temporal noise filter to the input file.",
            version: "1.0",
            aliases: ["mb"])

        @Option(name: [.short, .customLong("input")],
                 transform: URL.init(fileURLWithPath:))
        var inputURL: URL

        @Option(name: [.short, .customLong("output")],
                 transform: URL.init(fileURLWithPath:))
        var outputURL: URL

        @Argument(help: ArgumentHelp(
            "Noise filter strength between 0 - 1",
            valueName: "strength"))
        var noiseFilterStrength: Float = 0.5

        mutating func validate() throws {
            guard (0...1).contains(noiseFilterStrength) else {
                throw ValidationError("The motion blur strength must be between 0 and 1.0")
            }
        }
    }
}

extension ProcessVideoEffect.MotionBlur {

    mutating func run() async throws {

        do {

            try await withThrowingTaskGroup(of: Void.self) { taskGroup in

                let assetReader = AsyncAssetReader(inputURL: inputURL)

                let dimensions = try await assetReader.videoTrackDimensions()

                // Create `MotionBlurProcessor`.
                let blurProcessor = try MotionBlurProcessor(strength: motionBlurStrength,
                                                            inputDimensions: dimensions)

                let videoSettings = blurProcessor.sourcePixelBufferAttributes

                try await assetReader.configure(sourcePixelBufferAttributes: videoSettings)
                let assetReaderOutputStream = try await assetReader.outputStream()

                try await blurProcessor.setInputStream(assetReaderOutputStream)
                let blurProcessorOutputStream = try await blurProcessor.outputStream()

                let assetWriter = AsyncAssetWriter(outputURL: outputURL)
                try await assetWriter.setInputStream(blurProcessorOutputStream)

                taskGroup.addTask {
                    try await assetReader.run()
                }
                taskGroup.addTask {
                    try await blurProcessor.run()
                }

                taskGroup.addTask {
                    try await assetWriter.run()
                }

                try await taskGroup.waitForAll()

                await assetReader.finish()
                await blurProcessor.finish()
                await assetWriter.finish()

                NSWorkspace.shared.open(outputURL)
            }

        } catch {
            logger.error("### MotionBlur failed with error: \(error) ###")
        }
    }
}

extension ProcessVideoEffect.FrateRateConversion {

    mutating func run() async throws {

        do {

            try await withThrowingTaskGroup(of: Void.self) { taskGroup in

                let assetReader = AsyncAssetReader(inputURL: inputURL)

                let dimensions = try await assetReader.videoTrackDimensions()

                // Create `FrameRateConversionProcessor`.
                let frcProcessor = try FrameRateConversionProcessor(multiplier: frameRateMultiplier,
                                                                    inputDimensions: dimensions)

                let videoSettings = frcProcessor.sourcePixelBufferAttributes

                try await assetReader.configure(sourcePixelBufferAttributes: videoSettings)
                let assetReaderOutputStream = try await assetReader.outputStream()

                try await frcProcessor.setInputStream(assetReaderOutputStream)
                let frcProcessorOutputStream = try await frcProcessor.outputStream()

                let assetWriter = AsyncAssetWriter(outputURL: outputURL)
                try await assetWriter.setInputStream(frcProcessorOutputStream)

                taskGroup.addTask {
                    try await assetReader.run()
                }
                taskGroup.addTask {
                    try await frcProcessor.run()
                }

                taskGroup.addTask {
                    try await assetWriter.run()
                }

                try await taskGroup.waitForAll()

                await assetReader.finish()
                await frcProcessor.finish()
                await assetWriter.finish()

                NSWorkspace.shared.open(outputURL)
            }

        } catch {
            logger.error("### FrateRateConversion failed with error: \(error) ###")
        }
    }
}

extension ProcessVideoEffect.TemporalNoiseFilter {

    mutating func run() async throws {

        do {
            try await withThrowingTaskGroup(of: Void.self) { taskGroup in

                let assetReader = AsyncAssetReader(inputURL: inputURL)

                let dimensions = try await assetReader.videoTrackDimensions()

                // Create `TemporalNoiseFilter`.
                let noiseFilterProcessor = try TemporalNoiseFilter(strength: noiseFilterStrength,
                                                                   inputDimensions: dimensions)

                let videoSettings = noiseFilterProcessor.sourcePixelBufferAttributes

                try await assetReader.configure(sourcePixelBufferAttributes: videoSettings)
                let assetReaderOutputStream = try await assetReader.outputStream()

                try await noiseFilterProcessor.setInputStream(assetReaderOutputStream)
                let noiseFilterProcessorOutputStream = try await noiseFilterProcessor.outputStream()

                let assetWriter = AsyncAssetWriter(outputURL: outputURL)
                try await assetWriter.setInputStream(noiseFilterProcessorOutputStream)

                taskGroup.addTask {
                    try await assetReader.run()
                }
                taskGroup.addTask {
                    try await noiseFilterProcessor.run()
                }

                taskGroup.addTask {
                    try await assetWriter.run()
                }

                try await taskGroup.waitForAll()

                await assetReader.finish()
                await noiseFilterProcessor.finish()
                await assetWriter.finish()

                NSWorkspace.shared.open(outputURL)
            }

        } catch {
            logger.error("### noiseFilterProcessor failed with error: \(error) ###")
        }
    }
}
