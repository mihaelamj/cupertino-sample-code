/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file provides the view controller for the MetalFX sample.
*/

import Cocoa
import MetalKit

/// The macOS-specific view controller.
class AAPLViewController: NSViewController {
    var renderer: AAPLRenderer!
    var mtkView: MTKView!

    @IBOutlet var animationToggleButton: NSButton!
    @IBOutlet var resetHistoryToggleButton: NSButton!
    @IBOutlet var proceduralTextureToggleButton: NSButton!
    @IBOutlet var scalingModeComboButton: NSComboButton!
    @IBOutlet var scalingModeSegmentedControl: NSSegmentedControl!
    @IBOutlet var mipBiasControlsLabel: NSTextField!
    @IBOutlet var mipBiasLabel: NSTextField!
    @IBOutlet var mipBiasSlider: NSSlider!
    @IBOutlet var renderScaleLabel: NSTextField!
    @IBOutlet var renderScaleSlider: NSSlider!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = view as? MTKView else {
            print("The view attached to AAPLViewController is not an MTKView.")
            return
        }

        // Select the default Metal device.
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device.")
            return
        }

        mtkView.device = defaultDevice

        guard let newRenderer = AAPLRenderer(metalKitView: mtkView) else {
            print("The app is unable to create the renderer.")
            return
        }

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer

        optionsChanged(nil)
        scalingModeChanged(nil)
    }

    @IBAction func optionsChanged(_ sender: Any?) {
        renderer.animationEnabled = (animationToggleButton.state == .on)
        renderer.resetHistoryEnabled = (resetHistoryToggleButton.state == .on)
        renderer.proceduralTextureEnabled = (proceduralTextureToggleButton.state == .on)
        renderer.adjustRenderScale(renderScaleSlider.floatValue)
        renderScaleSlider.floatValue = renderer.renderTarget.renderScale
        renderScaleLabel.stringValue = String(format: "% 3d%%", arguments: [Int(renderScaleSlider.floatValue * 100)])
        
        if renderer.proceduralTextureEnabled {
            renderer.textureMipmapBias = 0
            mipBiasControlsLabel.isHidden = true
            mipBiasLabel.isHidden = true
            mipBiasSlider.isHidden = true
        } else {
            mipBiasControlsLabel.isHidden = false
            mipBiasLabel.isHidden = false
            mipBiasSlider.isHidden = false
            renderer.textureMipmapBias = mipBiasSlider.floatValue
            mipBiasLabel.stringValue = String(format: "% 1.3f", arguments: [mipBiasSlider.floatValue])
        }
    }

    @IBAction func scalingModeChanged(_ sender: Any?) {
        // Save the current mode to configure MetalFX if the combo button changes.
        let previousScalingMode = renderer.mfxScalingMode
        
        let index = scalingModeSegmentedControl.selectedSegment
        let currentScalingMode = AAPLScalingMode(rawValue: index)!
        renderer.mfxScalingMode = currentScalingMode
        
        if previousScalingMode != renderer.mfxScalingMode {
            renderer.setupMetalFX()
        }
        
        // If the effect isn’t available, the renderer picks a supported effect.
        // Set the control to the current applied effect.
        if renderer.mfxScalingMode != currentScalingMode {
            scalingModeSegmentedControl.selectedSegment = renderer.mfxScalingMode.rawValue
        }
    }
}
