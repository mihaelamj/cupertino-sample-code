/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller that hosts a `CanvasView` for the user to interact with.
*/

import UIKit

class ViewController: UIViewController, UIPencilInteractionDelegate {
    
    // MARK: Properties

    private var useDebugDrawing = false

    private let reticleView: ReticleView = {
        let view = ReticleView(frame: CGRect.null)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        return view
    }()

    @IBOutlet private weak var canvasView: CanvasView!
    @IBOutlet private weak var debugButton: UIButton!
    
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var forceLabel: UILabel!
    @IBOutlet private weak var azimuthAngleLabel: UILabel!
    @IBOutlet private weak var azimuthUnitVectorLabel: UILabel!
    @IBOutlet private weak var altitudeAngleLabel: UILabel!
    
    /// An IBOutlet Collection with all of the labels for touch values.
    @IBOutlet private var gagueLabelCollection: [UILabel]!
    
    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.addSubview(reticleView)
        
        // Start with debug drawing turned on.
        toggleDebugDrawing(sender: debugButton)
        clearGagues()
        
        if #available(iOS 12.1, *) {
            let pencilInteraction = UIPencilInteraction()
            pencilInteraction.delegate = self
            view.addInteraction(pencilInteraction)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                clearView(sender: traitCollection)
            }
        }
    }

    // MARK: Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)

        touches.forEach { (touch) in
            updateGagues(with: touch)
            
            if useDebugDrawing, touch.type == .pencil {
                reticleView.isHidden = false
                updateReticleView(with: touch)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)

        touches.forEach { (touch) in
            updateGagues(with: touch)
            
            if useDebugDrawing, touch.type == .pencil {
                updateReticleView(with: touch)
                
                // Use the last predicted touch to update the reticle.
                guard let predictedTouch = event?.predictedTouches(for: touch)?.last else { return }
                
                updateReticleView(with: predictedTouch, isPredicted: true)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)
        canvasView.endTouches(touches, cancel: false)

        touches.forEach { (touch) in
            clearGagues()
            
            if useDebugDrawing, touch.type == .pencil {
                reticleView.isHidden = true
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.endTouches(touches, cancel: true)

        touches.forEach { (touch) in
            clearGagues()
            
            if useDebugDrawing, touch.type == .pencil {
                reticleView.isHidden = true
            }
        }
    }

    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        canvasView.updateEstimatedPropertiesForTouches(touches)
    }

    // MARK: Actions

    @IBAction private func clearView(sender: Any) {
        canvasView.clear()
    }

    @IBAction private func toggleDebugDrawing(sender: UIButton) {
        canvasView.isDebuggingEnabled = !canvasView.isDebuggingEnabled
        useDebugDrawing.toggle()
        sender.isSelected = canvasView.isDebuggingEnabled
    }

    @IBAction private func toggleUsePreciseLocations(sender: UIButton) {
        canvasView.usePreciseLocations = !canvasView.usePreciseLocations
        sender.isSelected = canvasView.usePreciseLocations
    }

    // MARK: Convenience

    /// Gather the properties on a `UITouch` for force, altitude, azimuth and location.
    /// - Tag: PencilProperties
    private func updateReticleView(with touch: UITouch, isPredicted: Bool = false) {
        guard touch.type == .pencil else { return }

        reticleView.predictedDotLayer.isHidden = !isPredicted
        reticleView.predictedLineLayer.isHidden = !isPredicted

        let azimuthAngle = touch.azimuthAngle(in: canvasView)
        let azimuthUnitVector = touch.azimuthUnitVector(in: canvasView)
        let altitudeAngle = touch.altitudeAngle

        if isPredicted {
            reticleView.predictedAzimuthAngle = azimuthAngle
            reticleView.predictedAzimuthUnitVector = azimuthUnitVector
            reticleView.predictedAltitudeAngle = altitudeAngle
        } else {
            let location = touch.preciseLocation(in: canvasView)
            reticleView.center = location
            reticleView.actualAzimuthAngle = azimuthAngle
            reticleView.actualAzimuthUnitVector = azimuthUnitVector
            reticleView.actualAltitudeAngle = altitudeAngle
        }
    }
    
    private func updateGagues(with touch: UITouch) {
        forceLabel.text = touch.force.valueFormattedForDisplay ?? ""
        
        let azimuthUnitVector = touch.azimuthUnitVector(in: canvasView)
        azimuthUnitVectorLabel.text = azimuthUnitVector.valueFormattedForDisplay ?? ""
        
        let azimuthAngle = touch.azimuthAngle(in: canvasView)
        azimuthAngleLabel.text = azimuthAngle.valueFormattedForDisplay ?? ""
        
        // When using a finger, the angle is Pi/2 (1.571), representing a touch perpendicular to the device surface.
        altitudeAngleLabel.text = touch.altitudeAngle.valueFormattedForDisplay ?? ""
        
        let location = touch.preciseLocation(in: canvasView)
        locationLabel.text = location.valueFormattedForDisplay ?? ""
    }
    
    private func clearGagues() {
        gagueLabelCollection.forEach { (label) in
            label.text = ""
        }
    }

    /// A view controller extension that implements pencil interactions.
    /// - Tag: PencilInteraction
    @available(iOS 12.1, *)
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        guard UIPencilInteraction.preferredTapAction == .switchPrevious else { return }
        
        /* The tap interaction is a quick way for the user to switch tools within an app.
         Toggling the debug drawing mode from Apple Pencil is a discoverable action, as the button
         for debug mode is on screen and visually changes to indicate what the tap interaction did.
         */
        toggleDebugDrawing(sender: debugButton)
    }
}
