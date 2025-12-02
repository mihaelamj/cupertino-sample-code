/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller implementation for the Haptic Palette app.
*/

import UIKit

import CoreHaptics

class ViewController: UIViewController {
    
    // Touch Palettes:
    //@IBOutlet weak var transientPalette: UIView?
    //@IBOutlet weak var continuousPalette: UIView?
    
    // Views to represent 2D sliders.
    private var transientPalette: UIView!
    private var continuousPalette: UIView!
    
    // Views to show where the user last touched.
    private var transientTouchView: UIView!
    private var continuousTouchView: UIView!
    
    // Palette property labels to track values during press.
    private var transientTitleLabel: UILabel!
    private var transientValueLabel: UILabel!
    
    private var continuousTitleLabel: UILabel!
    private var continuousValueLabel: UILabel!
    
    // Haptic Engine & Player State:
    private var engine: CHHapticEngine!
    private var engineNeedsStart = true
    private var continuousPlayer: CHHapticAdvancedPatternPlayer!
    
    private lazy var supportsHaptics: Bool = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.supportsHaptics
    }()
    
    // Track the screen dimensions:
    private lazy var windowWidth: CGFloat = {
        return UIScreen.main.bounds.size.width
    }()
    
    private lazy var windowHeight: CGFloat = {
        return UIScreen.main.bounds.size.height
    }()
    
    // Constants
    private let margin: CGFloat = 16
    private let labelHeight: CGFloat = 24
    private let initialIntensity: Float = 1.0
    private let initialSharpness: Float = 0.5
    private let touchIndicatorSize: CGFloat = 50
    
    // Constant colors consistent across UI:
    private let padColor: UIColor = .systemGray3
    private let flashColor: UIColor = .systemGray2
    
    // Tokens to track whether app is in the foreground or the background:
    private var foregroundToken: NSObjectProtocol?
    private var backgroundToken: NSObjectProtocol?
    
    // Timer to handle transient haptic playback:
    private var transientTimer: DispatchSourceTimer?
    
    private lazy var paletteSize: CGFloat = {
        let totalWidth = windowWidth - 2 * margin
        let totalHeight = windowHeight - 80 - 4 * labelHeight - 2 * margin
        return min(totalWidth, totalHeight / 2)
    }()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Ensure the background matches the device appearance.
        self.view.backgroundColor = .systemBackground
        
        // Create & configure the engine before doing anything else, since the user may touch a pad immediately.
        if supportsHaptics {
            createAndStartHapticEngine()
            createContinuousHapticPlayer()
        }
        
        layoutPaletteViews()
        layoutTouchIndicators()
        addGestureRecognizers()
        
        layoutTitleLabels()
        layoutValueLabels()
        
        addObservers()
    }
    
    /// - Tag: CreateAndStartEngine
    func createAndStartHapticEngine() {
        
        // Create and configure a haptic engine.
        do {
            engine = try CHHapticEngine()
        } catch let error {
            fatalError("Engine Creation Error: \(error)")
        }
        
        // Mute audio to reduce latency for collision haptics.
        engine.playsHapticsOnly = true
        
        // The stopped handler alerts you of engine stoppage.
        engine.stoppedHandler = { reason in
            print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
            switch reason {
            case .audioSessionInterrupt:
                print("Audio session interrupt")
            case .applicationSuspended:
                print("Application suspended")
            case .idleTimeout:
                print("Idle timeout")
            case .systemError:
                print("System error")
            case .notifyWhenFinished:
                print("Playback finished")
            case .gameControllerDisconnect:
                print("Controller disconnected.")
            case .engineDestroyed:
                print("Engine destroyed.")
            @unknown default:
                print("Unknown error")
            }
        }
        
        // The reset handler provides an opportunity to restart the engine.
        engine.resetHandler = {
            
            print("Reset Handler: Restarting the engine.")
            
            do {
                // Try restarting the engine.
                try self.engine.start()
                
                // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
                self.engineNeedsStart = false
                
                // Recreate the continuous player.
                self.createContinuousHapticPlayer()
                
            } catch {
                print("Failed to start the engine")
            }
        }
        
        // Start the haptic engine for the first time.
        do {
            try self.engine.start()
        } catch {
            print("Failed to start the engine: \(error)")
        }
    }
    
    /// - Tag: CreateContinuousPattern
    func createContinuousHapticPlayer() {
        // Create an intensity parameter:
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity,
                                               value: initialIntensity)
        
        // Create a sharpness parameter:
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness,
                                               value: initialSharpness)
        
        // Create a continuous event with a long duration from the parameters.
        let continuousEvent = CHHapticEvent(eventType: .hapticContinuous,
                                            parameters: [intensity, sharpness],
                                            relativeTime: 0,
                                            duration: 100)
        
        do {
            // Create a pattern from the continuous haptic event.
            let pattern = try CHHapticPattern(events: [continuousEvent], parameters: [])
            
            // Create a player from the continuous haptic pattern.
            continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
            
        } catch let error {
            print("Pattern Player Creation Error: \(error)")
        }
        
        continuousPlayer.completionHandler = { _ in
            DispatchQueue.main.async {
                // Restore original color.
                self.continuousPalette.backgroundColor = self.padColor
            }
        }
    }
    
    // Layout two palettes and format their appearance.
    func layoutPaletteViews() {
        
        let xPalette = (windowWidth - paletteSize) / 2.0
        let yTop = windowHeight / 2 - margin - labelHeight - paletteSize
        let yBottom = windowHeight / 2 + labelHeight + margin
        
        let continuousFrame = CGRect(x: xPalette, y: yTop, width: paletteSize, height: paletteSize)
        let transientFrame = CGRect(x: xPalette, y: yBottom, width: paletteSize, height: paletteSize)
        
        transientPalette = UIView(frame: transientFrame)
        continuousPalette = UIView(frame: continuousFrame)
        
        formatPalette(transientPalette)
        formatPalette(continuousPalette)
        
        self.view.addSubview(transientPalette)
        self.view.addSubview(continuousPalette)
    }
    
    func formatPalette(_ palette: UIView) {
        palette.layer.cornerRadius = 16
        palette.backgroundColor = padColor
        palette.clipsToBounds = true
    }
    
    func layoutTouchIndicators() {
        
        // Start each touch indicator in the middle of the pad.
        let size = touchIndicatorSize
        let frame = CGRect(x: (paletteSize - size) / 2.0,
                           y: (paletteSize - size) / 2.0,
                           width: size,
                           height: size)
        
        transientTouchView = UIView(frame: frame)
        continuousTouchView = UIView(frame: frame)
        
        formatTouchView(transientTouchView)
        formatTouchView(continuousTouchView)
        
        transientPalette.addSubview(transientTouchView)
        continuousPalette.addSubview(continuousTouchView)
    }
    
    // Ensure all touch indicators share the same consistent appearance.
    func formatTouchView(_ touchView: UIView) {
        touchView.backgroundColor = #colorLiteral(red: 0.9696919322, green: 0.654135406, blue: 0.5897029042, alpha: 1)
        touchView.layer.cornerRadius = touchView.bounds.width / 2.0
    }
    
    func layoutTitleLabels() {
        let height = labelHeight
        let width = paletteSize
        
        let xLabel = transientPalette.frame.minX
        let yTransient = transientPalette.frame.minY - 2 - height
        let transientFrame = CGRect(x: xLabel, y: yTransient, width: width, height: height)
        
        let titleFont = UIFont.preferredFont(forTextStyle: .title2)
        
        transientTitleLabel = UILabel(frame: transientFrame)
        transientTitleLabel.textAlignment = .center
        transientTitleLabel.font = titleFont
        transientTitleLabel.text = "Transient"
        
        let yContinuous = continuousPalette.frame.minY - 2 - height
        let continuousFrame = CGRect(x: xLabel, y: yContinuous, width: width, height: height)
        
        continuousTitleLabel = UILabel(frame: continuousFrame)
        continuousTitleLabel.textAlignment = .center
        continuousTitleLabel.font = titleFont
        continuousTitleLabel.text = "Continuous"
        
        self.view.addSubview(transientTitleLabel)
        self.view.addSubview(continuousTitleLabel)
    }
    
    func layoutValueLabels() {
        
        let width = windowWidth
        let height = labelHeight
        
        let xLabel: CGFloat = 0
        let yTransient = transientPalette.frame.maxY + 2
        let yContinuous = continuousPalette.frame.maxY + 2
        
        let transientFrame = CGRect(x: xLabel, y: yTransient, width: width, height: height)
        let continuousFrame = CGRect(x: xLabel, y: yContinuous, width: width, height: height)
        
        let fontSize = UIFont.preferredFont(forTextStyle: .footnote).pointSize
        let monospacedDigitsFont = UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular)
        
        transientValueLabel = UILabel(frame: transientFrame)
        transientValueLabel.textAlignment = .center
        updateText(label: transientValueLabel, sharpness: 0.5, intensity: 0.5)
        transientValueLabel.font = monospacedDigitsFont
        
        continuousValueLabel = UILabel(frame: continuousFrame)
        continuousValueLabel.textAlignment = .center
        updateText(label: continuousValueLabel, sharpness: 0.5, intensity: 0.5)
        continuousValueLabel.font = monospacedDigitsFont
        
        self.view.addSubview(transientValueLabel)
        self.view.addSubview(continuousValueLabel)
    }
    
    private func addObservers() {
        backgroundToken = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                                 object: nil,
                                                                 queue: nil)
        { _ in
            guard self.supportsHaptics else {
                return
            }
            // Stop the haptic engine.
            self.engine.stop(completionHandler: { error in
                if let error = error {
                    print("Haptic Engine Shutdown Error: \(error)")
                    return
                }
                self.engineNeedsStart = true
            })
        }
        foregroundToken = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                                 object: nil,
                                                                 queue: nil)
        { _ in
            guard self.supportsHaptics else {
                return
            }
            // Restart the haptic engine.
            self.engine.start(completionHandler: { error in
                if let error = error {
                    print("Haptic Engine Startup Error: \(error)")
                    return
                }
                self.engineNeedsStart = false
            })
        }
    }
    
    func addGestureRecognizers() {
        
        let transientPress = UILongPressGestureRecognizer(target: self, action: #selector(transientPalettePressed))
        transientPress.minimumPressDuration = 0
        
        let continuousPress = UILongPressGestureRecognizer(target: self, action: #selector(continuousPalettePressed))
        continuousPress.minimumPressDuration = 0
        
        transientPalette.addGestureRecognizer(transientPress)
        continuousPalette.addGestureRecognizer(continuousPress)
    }
    
    @objc
    private func transientPalettePressed(_ press: UILongPressGestureRecognizer) {
        
        let location = press.location(in: transientPalette)
        
        // Clip location to the minimum and maximum values.
        let clippedLocation = clipLocation(location, toView: transientPalette)
        
        // Move the touch indicator to the latest touch point, so it follows the user's finger.
        transientTouchView.center = clippedLocation
        
        let (eventSharpness, eventIntensity) = sharpnessAndIntensityAt(location: location, in: transientPalette)
        
        // Update the labels to show the latest intensity and sharpness values.
        updateText(label: transientValueLabel,
                   sharpness: eventSharpness,
                   intensity: eventIntensity)
        
        switch press.state {
            
        case .began:
            
            // Highlight the touch point by enlargening and bolding the indicator.
            self.transientTouchView.alpha = 1
            
            // On first touch down, always play the haptic.
            playHapticTransient(time: 0,
                                intensity: eventIntensity,
                                sharpness: eventSharpness)
            
            // Create a timer to play subsequent transient patterns in succession.
            transientTimer?.cancel()
            transientTimer = DispatchSource.makeTimerSource(queue: .main)
            guard let timer = transientTimer else {
                return
            }
            
            timer.schedule(deadline: .now() + .milliseconds(750), repeating: .milliseconds(600))
            timer.setEventHandler() { [unowned self] in
                
                // Recalibrate sharpness and intensity each time the timer fires.
                let newLocation = press.location(in: self.transientPalette)
                let (sharpness, intensity) = self.sharpnessAndIntensityAt(location: newLocation, in: self.transientPalette)
                
                self.playHapticTransient(time: CHHapticTimeImmediate,
                                         intensity: intensity,
                                         sharpness: sharpness)
            }
            
            // Activate the timer.
            timer.resume()
            
        case .ended, .cancelled:
            
            // Stop the transient timer.
            transientTimer?.cancel()
            transientTimer = nil
            
        default:
            break
        }
    }
    
    /// - Tag: PlayTransientPattern
    // Play a haptic transient pattern at the given time, intensity, and sharpness.
    private func playHapticTransient(time: TimeInterval,
                                     intensity: Float,
                                     sharpness: Float) {
        
        // Abort if the device doesn't support haptics.
        if !supportsHaptics {
            return
        }
        
        // Flash the pad background to indicate that the timer fired.
        self.flashBackground(in: self.transientPalette)
        
        // Create an event (static) parameter to represent the haptic's intensity.
        let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity,
                                                        value: intensity)
        
        // Create an event (static) parameter to represent the haptic's sharpness.
        let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness,
                                                        value: sharpness)
        
        // Create an event to represent the transient haptic pattern.
        let event = CHHapticEvent(eventType: .hapticTransient,
                                  parameters: [intensityParameter, sharpnessParameter],
                                  relativeTime: 0)
        
        // Create a pattern from the haptic event.
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            
            // Create a player to play the haptic pattern.
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate) // Play now.
        } catch let error {
            print("Error creating a haptic transient pattern: \(error)")
        }
    }
    
    @objc
    private func continuousPalettePressed(_ press: UILongPressGestureRecognizer) {
        
        let location = press.location(in: continuousPalette)
        
        // Clip location to the minimum and maximum values, then normalize to [0,1].
        let clippedLocation = clipLocation(location, toView: continuousPalette)
        let normalizedLocation = normalizeCoordinates(clippedLocation, toView: continuousPalette)
        
        // The intensity should be highest at the top, opposite of the iOS y-axis direction, so subtract.
        let dynamicIntensity: Float = 1 - Float(normalizedLocation.y)
        
        // Dynamic parameters range from -0.5 to 0.5 to map the final sharpness to the [0,1] range.
        let dynamicSharpness: Float = Float(normalizedLocation.x) - 0.5
        
        // Move the continuous touch indicator to the touch's location.
        continuousTouchView.center = clippedLocation
        
        // The perceived intensity value multiplies the original event parameter intensity by the dynamic parameter's value.
        let perceivedIntensity = initialIntensity * dynamicIntensity
        
        // The perceived sharpness value adds the dynamic parameter to the original pattern's event parameter sharpness.
        let perceivedSharpness = initialSharpness + dynamicSharpness
        
        // Update the labels to show the latest intensity and sharpness values.
        updateText(label: continuousValueLabel,
                   sharpness: perceivedSharpness,
                   intensity: perceivedIntensity)
        
        if supportsHaptics {
            // Create dynamic parameters for the updated intensity & sharpness.
            let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                              value: dynamicIntensity,
                                                              relativeTime: 0)
            
            let sharpnessParameter = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                                              value: dynamicSharpness,
                                                              relativeTime: 0)
            
            // Send dynamic parameters to the haptic player.
            do {
                try continuousPlayer.sendParameters([intensityParameter, sharpnessParameter],
                                                    atTime: 0)
            } catch let error {
                print("Dynamic Parameter Error: \(error)")
            }
        }
        
        switch press.state {
        case .began:
        
            // Highlight the touch point by enlargening and boldening indicator.
            self.continuousTouchView.alpha = 1
            
            // Proceed if and only if the device supports haptics.
            if supportsHaptics {
                
                // Warm engine.
                do {
                    // Begin playing continuous pattern.
                    try continuousPlayer.start(atTime: CHHapticTimeImmediate)
                } catch let error {
                    print("Error starting the continuous haptic player: \(error)")
                }
                
                // Darken the background.
                self.continuousPalette.backgroundColor = self.flashColor
            }
            
        case .ended, .cancelled:
            
            if supportsHaptics {
                // Stop playing the haptic pattern.
                do {
                    try continuousPlayer.stop(atTime: CHHapticTimeImmediate)
                } catch let error {
                    print("Error stopping the continuous haptic player: \(error)")
                }
                
                // The background color returns to normal in the player's completion handler.
            }
            
        default: break // Do nothing.
        }
    }
    
    // --- HELPER FUNCTIONS ---
    
    // Helper function to change the background color briefly to indicate the transient timer fired.
    private func flashBackground(in viewToFlash: UIView) {
        
        viewToFlash.backgroundColor = self.flashColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(30), execute: {
            
            viewToFlash.backgroundColor = self.padColor
        })
    }
    
    // Helper function to compute the sharpness and intensity at a specified point inside a pad.
    private func sharpnessAndIntensityAt(location: CGPoint, in view: UIView) -> (Float, Float) {
        
        // Clip location to the minimum and maximum values.
        let clippedLocation = clipLocation(location, toView: view)
        
        // Normalize coordinates to a [0, 1] spectrum.
        let normalizedLocation = normalizeCoordinates(clippedLocation, toView: view)
        
        // The intensity should be highest at the top, opposite of the iOS y-axis direction, so subtract.
        let eventIntensity: Float = 1 - Float(normalizedLocation.y)
        
        // The sharpness spectrum is 0 to 1. Map the x-coordinate to that range.
        let eventSharpness: Float = Float(normalizedLocation.x)
        
        return (eventSharpness, eventIntensity)
    }
    
    // Helper function to clip a touch location to the bounds of a palette view:
    private func clipLocation(_ point: CGPoint, toView clipView: UIView) -> CGPoint {
        
        var clippedLocation = point
        
        if point.x < 0 {
            clippedLocation.x = 0
        } else if point.x > clipView.bounds.width {
            clippedLocation.x = clipView.bounds.width
        }
        
        if point.y < 0 {
            clippedLocation.y = 0
        } else if point.y > clipView.bounds.height {
            clippedLocation.y = clipView.bounds.height
        }
        
        return clippedLocation
    }
    
    /// - Tag: NormalizeCoordinates
    // Helper function to normalize a touch location within a palette view:
    private func normalizeCoordinates(_ point: CGPoint, toView paletteView: UIView) -> CGPoint {
        
        let width = paletteView.bounds.width
        let height = paletteView.bounds.height
        
        return CGPoint(x: point.x / width,
                       y: point.y / height)
    }
    
    // Helper function to update a label as the user's touch moves across a palette:
    private func updateText(label: UILabel, sharpness: Float, intensity: Float) {
        label.text = String(format: "Sharpness %.2f, Intensity %.2f", sharpness, intensity)
    }
    
}
