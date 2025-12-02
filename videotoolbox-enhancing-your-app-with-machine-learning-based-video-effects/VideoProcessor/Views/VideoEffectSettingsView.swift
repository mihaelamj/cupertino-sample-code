/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `VideoEffectSettingsView`, which displays the
 proper view for the selected video effect.
*/

import SwiftUI
internal import CoreMedia

struct VideoEffectSettingsView: View {

    let effect: VideoEffect

    @Environment(VideoProcessorModel.self) private var model
    @Environment(VideoProcessor.self) private var processor

    var body: some View {

        List {

            Section(header: VideoEffectLabel(effect: effect)) {

                switch effect {
                case .frameRateConversion:
                    FrameRateConversionView()
                case .motionBlur:
                    MotionBlurView()
                case .superResolutionScaler:
                    SuperResolutionScalerView()
                case .temporalNoiseFilter:
                    TemporalNoiseFilterView()
                case .lowLatencySuperResolutionScaler:
                    LowLatencySuperResolutionScalerView()
                case .lowLatencyFrameInterpolation:
                    LowLatencyFrameInterpolationView()
                }
            }
            HStack {

                Button("Exit") {
                    model.selectedVideoEffect = nil
                    model.setState(.idle)
                }
                .disabled(model.busy)

                Spacer()

                if model.isEffectSupported(effect) {
                    Button("Start Processing") {
                        processor.startProcessing(effect: effect)
                    }
                    .disabled(model.ready == false)
                }
            }
            .padding(.top)
        }
        .disabled(model.busy)
    }
}

struct FrameRateConversionView: View {

    @Environment(VideoProcessorModel.self) private var model

    var body: some View {

        Menu("Multiplier: \(model.frcMultiplier) ") {
            ForEach(model.frcValidMultipliers, id: \.self) { multiplier in
                Button { model.frcMultiplier = multiplier } label: { Text(String(multiplier)) }
            }
        }
    }
}

struct MotionBlurView: View {

    @Environment(VideoProcessorModel.self) private var model

    var body: some View {

        @Bindable var model = model

        HStack {
            Text("Strength")

            Slider(value: $model.blurStrength, in: 1...100)

            Text("\(Int(model.blurStrength))")
        }
    }
}

struct SuperResolutionScalerView: View {

    @Environment(VideoProcessorModel.self) private var model

    var body: some View {

        Menu("Scale Factor: \(model.srsScaleFactor) ") {
            ForEach(model.srsValidScaleFactors, id: \.self) { scale in
                Button { model.srsScaleFactor = scale } label: { Text(String(scale)) }
            }
        }
    }
}

struct TemporalNoiseFilterView: View {

    @Environment(VideoProcessorModel.self) private var model

    var body: some View {

        @Bindable var model = model

        HStack {
            Text("Strength")

            Slider(value: $model.noiseFilterStrength, in: 0.0...1.0)

            Text("\(String(format: "%.2f", model.noiseFilterStrength))")
        }
    }
}

struct LowLatencySuperResolutionScalerView: View {

    @Environment(VideoProcessorModel.self) private var model

    var body: some View {

        VStack {

            Text("Supported Resolution:")
                .font(.subheadline)
                .foregroundColor(.gray)

            if let minimumDimensions = model.llsrsMinimumDimensions,
               let maximumDimensions = model.llsrsMaximumDimensions {
                Text("\(minimumDimensions.width) x \(minimumDimensions.height) to \(maximumDimensions.width) x \(maximumDimensions.height)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
            }

            Menu("Scale Factor: \(String(format: "%.1f", model.llsrsScaleFactor))") {
                ForEach(model.llsrsSupportedScaleFactors, id: \.self) { scale in
                    Button { model.llsrsScaleFactor = scale } label: {
                        Text(String(format: "%.1f", scale))
                    }
                }
            }
        }
    }
}

struct LowLatencyFrameInterpolationView: View {

    @Environment(VideoProcessorModel.self) private var model

    var body: some View {

        VStack {

            Menu("Frames added: \(model.llfiNumFramesBetween) ") {
                ForEach(model.llfiFrcValidFrameNumbers, id: \.self) { multiplier in
                    Button { model.llfiNumFramesBetween = multiplier } label: { Text(String(multiplier)) }
                }
            }

            Menu("Scale by: \(model.llfiScalarMultiplier) ") {
                ForEach(model.llfiValidScalarMultiplier, id: \.self) { multiplier in
                    Button { model.llfiScalarMultiplier = multiplier } label: { Text(String(multiplier)) }
                }
            }
        }
    }
}
