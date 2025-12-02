/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the model for `VideoProcessorApp`.
*/

import Foundation
import SwiftUI
@preconcurrency import VideoToolbox

enum VideoEffect {
    case frameRateConversion
    case motionBlur
    case superResolutionScaler
    case temporalNoiseFilter
    case lowLatencySuperResolutionScaler
    case lowLatencyFrameInterpolation
}

@MainActor
@Observable
final class VideoProcessorModel: Sendable {

    enum State {
        case idle
        case ready(inputURL: URL)
        case processing(progress: Double?)
        case completed(outputURL: URL)
        case failed(error: Error)
    }

    var state: State = .idle
    func setState(_ state: State) { self.state = state }

    // The current video effect.
    var selectedVideoEffect: VideoEffect?

    // Parameters for the motion blur.
    var blurStrength = 50.0

    // Parameters for the temporal noise filter.
    var noiseFilterStrength = 0.5

    // Parameters for the frame rate conversion.
    var frcMultiplier = 4
    var frcValidMultipliers = [2, 3, 4, 5, 6, 7, 8]

    // Parameters for the super-resolution scaler.
    var srsScaleFactor = 4
    var srsValidScaleFactors: [Int] = superResolutionScaleFactors()

    // Parameters for the low-latency super-resolution scaler.
    var llsrsScaleFactor: Float = 2
    var llsrsSupportedScaleFactors: [Float] = [2, 4]
    var llsrsMinimumDimensions = lowLatencySuperResolutionScalerMinimumDimensions()
    var llsrsMaximumDimensions = lowLatencySuperResolutionScalerMaximumDimensions()

    // Parameters for the low-latency interpolation.
    var llfiNumFramesBetween = 1
    var llfiScalarMultiplier = 1

    var llfiFrcValidFrameNumbers = [1, 2, 3]
    var llfiValidScalarMultiplier = [1, 2]
}

extension VideoProcessorModel {

    var ready: Bool {
        switch state {
        case .ready:
            return true
        default:
            return false
        }
    }

    var busy: Bool {
        switch state {
        case .processing(_):
            return true
        default:
            return false
        }
    }
}

extension VideoProcessorModel {

    func isEffectSupported(_ effect: VideoEffect) -> Bool {

        switch effect {
        case .frameRateConversion:
            return true
        case .motionBlur:
            return true
        case .superResolutionScaler:
            return VTSuperResolutionScalerConfiguration.isSupported
        case .temporalNoiseFilter:
            return VTTemporalNoiseFilterConfiguration.isSupported
        case .lowLatencySuperResolutionScaler:
            return VTLowLatencySuperResolutionScalerConfiguration.isSupported
        case .lowLatencyFrameInterpolation:
            return VTLowLatencyFrameInterpolationConfiguration.isSupported
        }
    }
}
