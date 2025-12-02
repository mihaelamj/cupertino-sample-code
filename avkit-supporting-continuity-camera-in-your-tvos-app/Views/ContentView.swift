/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI
import AVFoundation

struct ContentView: View {

    /// The app's capture manager instance.
    @ObservedObject var captureManager: CaptureManager

    /// Generates photos and saves them to files.
    @ObservedObject var photoCapturer: PhotoCapturer

    /// Generates video recordings and saves each to file.
    @ObservedObject var videoCapturer: VideoCapturer

    /// Generates audio recordings and saves each to a file.
    @ObservedObject var audioCapturer: AudioCapturer

    /// Represents what the app is set to capture, typically photos or videos.
    @State private var captureType = CaptureType.photo

    /// A Boolean value that indicates whether the main view uses a flash
    /// animation to indicate that it's capturing a photo.
    @State private var showScreenFlash = false

    /// A temporary preview of the most recently captured photo.
    @State private var previewImage: UIImage?

    /// A Boolean value that indicates whether the app shows the Continuity Device Picker.
    @State private var showContinuityDevicePicker = false

    var body: some View {
        ZStack {
            if captureManager.isActive {
                CameraPreview(layer: captureManager.previewLayer)
                    .overlay {
                        if let image = previewImage {
                            previewImageOverlay(image)
                        }
                    }
                    .ignoresSafeArea()
                if captureType == .audio {
                    cameraFeedIsPausedOverlay
                }
            } else {
                Label("Continuity device not connected", systemImage: "video.slash.fill")
            }
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    timerView
                    Spacer()
                    if captureType != .audio {
                        buildEffectIndicators()
                    }
                }
                Spacer()
                if captureType == .audio {
                    AudioControls(audioCapturer: audioCapturer)
                    Divider()
                }
                ZStack {
                    HStack {
                        Spacer()
                        CaptureButton(action: onShutterButton,
                                      captureType: $captureType,
                                      captureState: captureState)
                        .disabled(!captureManager.isActive)
                        Spacer()
                    }
                    HStack(alignment: .bottom) {
                        captureTypePicker
                            .disabled(captureState != nil)
                        Spacer()
                        continuityDevicePickerButton
                    }
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
        .overlay {
            if showScreenFlash {
                screenFlashOverlay
            }
        }
        .continuityDevicePicker(isPresented: $showContinuityDevicePicker,
                                onDidConnect: handleNewConnectionForDevice)
        .task {
            // Shows the picker when app has no continuity device at launch.
            if !captureManager.activateDefaultContinuityCameraDevice() {
                showContinuityDevicePicker = true
            }
        }
    }
}

// MARK: - Helper properties

extension ContentView {

    /// Returns the current state of the audio or video capture, if applicable.
    private var captureState: CaptureState? {
        switch captureType {
            case .photo:
                return nil
            case .video:
                return videoCapturer.captureState
            case .audio:
                return audioCapturer.captureState
        }
    }

    /// Generates a picker for selecting between photo, video, and audio capture modes.
    private var captureTypePicker: some View {
        Picker(selection: captureTypeBinding) {
            captureTypeLabel(for: .photo)
            captureTypeLabel(for: .video)
            captureTypeLabel(for: .audio)
        } label: {
            captureTypeLabel(for: captureType)
        }
        .pickerStyle(.menu)
        .labelStyle(.titleAndIcon)
    }

    /// Generates a group of labels for the app's capture modes.
    ///
    /// - Parameter captureType: The capture mode type, such as photo, video, or audio.
    @ViewBuilder
    private func captureTypeLabel(for captureType: CaptureType) -> some View {
        Group {
            switch captureType {
                case .photo:
                    Label("photo", systemImage: "camera")
                case .video:
                    Label("video", systemImage: "video")
                case .audio:
                    Label("audio", systemImage: "mic")
            }
        }
        .tag(captureType)
    }

    private var captureTypeBinding: Binding<CaptureType> {
        .init {
            return captureType
        } set: { newValue in
            withAnimation { captureType = newValue }
            configureSessionForCaptureType(newValue)
        }
    }

    /// Starts or stops the capture session based on a capture type.
    private func configureSessionForCaptureType(_ captureType: CaptureType) {
        switch captureType {
            case .photo:
                captureManager.startIfNeeded()
            case .video:
                captureManager.startIfNeeded()
            case .audio:
                captureManager.stop()
        }
    }

    // MARK: - Timer

    /// Generates a timer view that shows the duration of a recording so far.
    @ViewBuilder
    private var timerView: some View {
        switch captureType {
            case .video:
                if case let .recording(start) = videoCapturer.captureState {
                    TimerView(startDate: start)
                } else {
                    TimerView(startDate: nil)
                }
            case .audio:
                if case let .recording(start) = audioCapturer.captureState {
                    TimerView(startDate: start)
                } else {
                    TimerView(startDate: nil)
                }
            default:
                EmptyView()
        }
    }

    // MARK: - Effects

    /// Generates a horizontal stack of indicators for the center stage, portrait, and studio light camera effects.
    @ViewBuilder
    private func buildEffectIndicators() -> some View {
        HStack(spacing: 10) {
            VideoEffectIndicator(observer: captureManager.videoEffectsObvserver.centerStageEffect,
                                 systemImage: "person.fill.viewfinder")
            VideoEffectIndicator(observer: captureManager.videoEffectsObvserver.portraitEffect,
                                 systemImage: "person.crop.square.fill")
        }
    }

    // MARK: - Photo / Video capturing

    /// Responds to a shutter button press by taking a photo or starting a video recording.
    private func onShutterButton() {
        switch captureType {
            case .photo:
                photoCapturer.onPhotoCompletion = { image in
                    showScreenFlash = true
                    previewImage = image
                }
                photoCapturer.capture()
            case .video:
                toggleVideoCapture()
            case .audio:
                toggleAudioCapture()
        }
    }

    /// Starts a new video recording, or stops a video recording the app previously started.
    private func toggleVideoCapture() {
        if case .recording = videoCapturer.captureState {
            videoCapturer.stopRecording()
        } else {
            videoCapturer.startRecording(with: captureManager)
        }
    }

    /// Starts a new audio recording, or stops an audio recording the app previously started.
    private func toggleAudioCapture() {
        if case .recording = audioCapturer.captureState {
            audioCapturer.stopRecording()
        } else {
            Task {
                await audioCapturer.startRecording()
            }
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var cameraFeedIsPausedOverlay: some View {
        Group {
            Rectangle()
                .fill(.ultraThinMaterial)
            Label("Camera feed is paused", systemImage: "pause.circle")
                .foregroundColor(.secondary)
        }
        .transition(.opacity)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var screenFlashOverlay: some View {
        FlashAndFade(visibleDuration: 0.1) {
            Rectangle()
                .fill(.white)
                .ignoresSafeArea()
        } completion: {
            showScreenFlash = false
        }
    }

    @ViewBuilder
    private func previewImageOverlay(_ image: UIImage) -> some View {
        FlashAndFade(visibleDuration: 3.0) {
            Image(uiImage: image)
                .resizable()
        } completion: {
            previewImage = nil
        }
    }
}

// MARK: - Continuity Camera extensions -

extension ContentView {

    /// Generates a button for the Continuity Device Picker.
    private var continuityDevicePickerButton: some View {
        Button {
            showContinuityDevicePicker.toggle()
        } label: {
            Label("Camera Picker", systemImage: "video.fill.badge.ellipsis")
        }
        .labelStyle(.iconOnly)
    }

    /// Responds to a person selecting a device with the Continuity Device Picker.
    ///
    /// - Parameter device: A continuity device from the Picker.
    /// - Tag: ContentView-handleNewConnectionForDevice
    func handleNewConnectionForDevice(_ device: AVContinuityDevice?) {
        guard let device else {
            print("The Continuity Device Picker didn't connect a device.")
            return
        }

        guard let firstCamera = device.videoDevices.first else {
            print("The Continuity Device Picker doesn't have any cameras.")
            return
        }

        captureManager.setActiveVideoInput(firstCamera,
                                           isUserPreferredCamera: true)
    }
}

struct VideoEffectIndicator: View {
    
    @ObservedObject var observer: CaptureDevicePropertyObserver
    
    var systemImage: String
    
    var body: some View {
        Image(systemName: systemImage)
            .font(.title2)
            .padding(4)
            .background {
                if observer.active {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                }
            }
    }
}
