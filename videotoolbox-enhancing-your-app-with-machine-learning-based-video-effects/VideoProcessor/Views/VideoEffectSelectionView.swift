/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `VideoEffectSelectionView`, which allows someone to select
 the video effect to demonstrate.
*/

import SwiftUI

struct VideoEffectSelectionView: View {

    var body: some View {

        List {

            Section(header: Label("Video Effects", systemImage: "video.fill")) {
                VideoEffectButton(effect: .frameRateConversion)
                VideoEffectButton(effect: .motionBlur)
                VideoEffectButton(effect: .superResolutionScaler)
                VideoEffectButton(effect: .temporalNoiseFilter)
            }
            
            Section(header: Label("Low Latency Effects", systemImage: "person.crop.square.badge.video.fill")) {
                VideoEffectButton(effect: .lowLatencyFrameInterpolation)
                VideoEffectButton(effect: .lowLatencySuperResolutionScaler)
            }
        }
    }
}

struct VideoEffectButton: View {

    let effect: VideoEffect
    @Environment(VideoProcessorModel.self) private var model

    var body: some View {

        Button {
            if let url = effect.assetURL {
                model.selectedVideoEffect = effect
                model.setState(.ready(inputURL: url))
            }

        } label: {

            VideoEffectLabel(effect: effect)
        }
        .disabled(model.isEffectSupported(effect) == false)
    }
}

struct VideoEffectLabel: View {

    let effect: VideoEffect

    var body: some View {

        HStack {
            effect.image.blur(radius: effect == .motionBlur ? 1.0 : 0.0)
                .foregroundColor(.accentColor)
            Text(effect.description)

            Spacer()
        }
    }
}

extension VideoEffect {
    var image: Image {
        switch self {
        case .frameRateConversion: Image(systemName: "film.stack")
        case .motionBlur: Image(systemName: "film")
        case .superResolutionScaler: Image("custom.film.square.stack")
        case .lowLatencySuperResolutionScaler: Image("custom.film.square.stack")
        case .lowLatencyFrameInterpolation: Image(systemName: "film.stack")
        case .temporalNoiseFilter: Image(systemName: "timer.square")
        }
    }
}

extension VideoEffect {
    public var assetURL: URL? {
        let assetPath = switch self {
        case .frameRateConversion: "EmbeddedAssets/FRC.mov"
        case .motionBlur: "EmbeddedAssets/MB.mov"
        case .superResolutionScaler: "EmbeddedAssets/SRS.mov"
        case .lowLatencySuperResolutionScaler: "EmbeddedAssets/LLSRS.mov"
        case .lowLatencyFrameInterpolation: "EmbeddedAssets/LLFI.mov"
        case .temporalNoiseFilter: "EmbeddedAssets/TNF.mov"
        }
        return Bundle.main.resourceURL?.appendingPathComponent(assetPath)
    }
}

extension VideoEffect: CustomStringConvertible, CaseIterable {

    public var description: String {
        switch self {
        case .frameRateConversion: "Frame Rate Conversion"
        case .motionBlur: "Motion Blur"
        case .superResolutionScaler: "Super Resolution Scaler"
        case .lowLatencySuperResolutionScaler: "Low Latency Super Resolution Scaler"
        case .lowLatencyFrameInterpolation: "Low Latency Frame Interpolation"
        case .temporalNoiseFilter: "Temporal Noise Filter"

        @unknown default: "Unknown"
        }
    }

    public static var allCases: [VideoEffect] { [.frameRateConversion,
                                                 .motionBlur,
                                                 superResolutionScaler,
                                                 lowLatencySuperResolutionScaler,
                                                 lowLatencyFrameInterpolation,
                                                 temporalNoiseFilter] }
}

extension VideoEffect {
    public var showProgress: Bool {
        switch self {
        case .frameRateConversion, .motionBlur, .superResolutionScaler, .temporalNoiseFilter:
            return true
        case .lowLatencySuperResolutionScaler, .lowLatencyFrameInterpolation:
            return false
        }
    }
}
