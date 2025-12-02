# Enhancing your app with machine-learning-based video effects
Add powerful effects to your videos using the VideoToolbox VTFrameProcessor API.

## Overview

> Note: This sample code project is associated with WWDC25 session 300:
[Enhance your app with machine-learning-based video effects](https://developer.apple.com/videos/play/wwdc2025/300).

Using this sample app, you can learn how to enhance your videos using one of several video effects.

`VTFrameRateConversion` allows you to add interpolated frames in between the existing frames of a video track, increasing the frame rate. You can use this to either reduce the jerkiness that short exposure times cause, or to allow smooth playback at slower speeds.

See the example in [`FrameRateConversionProcessor.swift`](VideoProcessor/Processing/FrameRateConversionProcessor.swift).

`VTMotionBlur` allows you to blur the regions of the video that have movement between frames. This can reduce jarring frame transitions and add a cinematic quality to the video tracks.

See the example in [`MotionBlurProcessor.swift`](VideoProcessor/Processing/MotionBlurProcessor.swift).

`VTSuperResolutionScaler` allows you to increase the spatial resolution of a video track by using information from previous and subsequent frames to recover detail and improve the overall look of the video.

See the example in [`SuperResolutionScaler.swift`](VideoProcessor/Processing/SuperResolutionScaler.swift).

`LowLatencyFrameInterpolation` allows you to increase the temporal resolution of a real-time video stream by using information from previous and subsequent frames to add interpolation frames, reducing jitter. Optionally also allows you to double the spatial resolution.

See the example in [`LowLatencyFrameInterpolation.swift`](VideoProcessor/Processing/LowLatencyFrameInterpolation.swift).

`LowLatencySuperResolutionScaler` allows you to increase the spatial resolution of a real-time video stream, delivering sharper details and reducing compression artifacts from low-resolution, low-bitrate sources. Optimized for video conferencing, it operates with minimal latency, power, and memory usage.

See the example in [`LowLatencySuperResolutionScaler.swift`](VideoProcessor/Processing/LowLatencySuperResolutionScaler.swift).

`TemporalNoiseFilter` allows you to remove noise from a video stream by using information from previous and subsequent frames to improve the overall look of the video.

See the example in [`TemporalNoiseFilter.swift`](VideoProcessor/Processing/TemporalNoiseFilter.swift).
