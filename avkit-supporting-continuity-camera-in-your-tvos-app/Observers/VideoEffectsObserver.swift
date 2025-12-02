/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observation that monitors individual `AVCaptureDevice` properties,
 and an observer type that monitors and manages multiple observations.
*/

import AVFoundation

/// A class that monitors the video effect properties of a camera instance.
class VideoEffectsObserver: ObservableObject {

    /// An array of observations that update the UI to reflect changes with
    /// the camera's video effects.
    private var videoEffectObservers = [NSKeyValueObservation]()

    /// An observation that monitors whether a camera's Center Stage video effect is active.
    var centerStageEffect = CaptureDevicePropertyObserver("Center Stage",
                                                          path: \.isCenterStageActive)

    /// An observation that monitors whether a camera's Portrait Effect video effect is active.
    var portraitEffect = CaptureDevicePropertyObserver("Portrait Effect",
                                                       path: \.isPortraitEffectActive)

    /// Changes the camera the observer's individual video effect observers monitor.
    /// - Parameter camera: An AV capture device that represents a camera.
    func observeCamera(_ camera: AVCaptureDevice) {
        // Update the Center Stage observer to monitor the new camera.
        centerStageEffect.observeCamera(camera)
        centerStageEffect.setCurrentState(camera.isCenterStageActive)

        // Update the Portrait Effect observer to monitor the new camera.
        portraitEffect.observeCamera(camera)
        portraitEffect.setCurrentState(camera.isPortraitEffectActive)
    }
}

/// Monitors an individual video effect property for activity.
/// - Tag: CaptureDevicePropertyObserver
class CaptureDevicePropertyObserver: ObservableObject {

    /// The name of the effect.
    let name: String

    /// The path to an AV capture device property.
    let path: KeyPath<AVCaptureDevice, Bool>

    /// An observation that monitors changes to a capture device's property.
    var observation: NSKeyValueObservation?

    /// A Boolean value that indicates whether the camera is currently using the effect.
    @Published var active = false

    init(_ effectName: String,
         path effectPath: KeyPath<AVCaptureDevice, Bool>) {

        name = effectName
        path = effectPath
    }

    /// Changes which camera the video effect observer monitors for property changes.
    /// - Parameter camera: An AV capture device that represents a camera.
    func observeCamera(_ camera: AVCaptureDevice) {
        // Clears out the current observation, if applicable.
        if let observation {
            observation.invalidate()
            self.observation = nil
        }

        // Sets the activity state to false before transitioning to the new camera.
        if active { setCurrentState(false) }

        // Creates an observation to monitor property changes for the camera.
        observation = camera.observe(path, options: [.new]) { _, change in
            let active = change.newValue ?? false

            // Prints the new state to the console.
            var message = "[Video Effect] \"\(self.name)\""
            message += " is now " + (active ? "active" : "inactive")
            print(message)

            self.setCurrentState(active)
        }
    }

    /// Updates the published Boolean property on the main thread for UI elements
    /// that may depend on it.
    /// - Parameter active: A Boolean that indicates whether the feature is active.
    func setCurrentState(_ active: Bool) {
        DispatchQueue.main.async {
            self.active = active
        }
    }
}
