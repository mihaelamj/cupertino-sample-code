/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file provides the view controller for the MetalFX sample.
*/

import UIKit
import MetalKit

/// The iOS-specific view controller.
class AAPLViewController: UIViewController {
    var renderer: AAPLRenderer!
    var mtkView: MTKView!
    
    @IBOutlet var animationSwitch: UISwitch!
    @IBOutlet var resetHistorySwitch: UISwitch!
    @IBOutlet var textureMotionSwitch: UISwitch!
    @IBOutlet var proceduralTextureSwitch: UISwitch!
    @IBOutlet var scalingModeSegmentedControl: UISegmentedControl!
    @IBOutlet var renderScaleSlider: UISlider!
    @IBOutlet var renderScaleLabel: UILabel!
    @IBOutlet var mipBiasControlsLabel: UILabel!
    @IBOutlet var mipBiasSlider: UISlider!
    @IBOutlet var mipBiasLabel: UILabel!
    
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

        iOSOptionsChanged(nil)
        iOSScalingModeChanged(nil)
    }
    
    @IBAction func iOSOptionsChanged(_ sender: Any?) {
        renderer.animationEnabled = animationSwitch.isOn
        renderer.resetHistoryEnabled = resetHistorySwitch.isOn
        renderer.proceduralTextureEnabled = proceduralTextureSwitch.isOn
        
        renderer.adjustRenderScale(renderScaleSlider.value)
        renderScaleSlider.value = renderer.renderTarget.renderScale
        renderScaleLabel.text = String(format: "% 3d%%", arguments: [Int(renderScaleSlider.value * 100)])
        
        if renderer.proceduralTextureEnabled {
            renderer.textureMipmapBias = 0
            mipBiasControlsLabel.isHidden = true
            mipBiasLabel.isHidden = true
            mipBiasSlider.isHidden = true
        } else {
            mipBiasControlsLabel.isHidden = false
            mipBiasLabel.isHidden = false
            mipBiasSlider.isHidden = false
            renderer.textureMipmapBias = mipBiasSlider.value
            mipBiasLabel.text = String(format: "% 1.3f", arguments: [mipBiasSlider.value])
        }
    }
    
    @IBAction func iOSScalingModeChanged(_ sender: Any?) {
        // Save the current mode to configure MetalFX if the combo button changes.
        let previousScalingMode = renderer.mfxScalingMode

        // Set the current scaling mode.
        let index = scalingModeSegmentedControl.selectedSegmentIndex
        let currentScalingMode = AAPLScalingMode(rawValue: index)!
        renderer.mfxScalingMode = currentScalingMode
                
        if previousScalingMode != renderer.mfxScalingMode {
            renderer.setupMetalFX()
        }
        
        // If the effect isn’t available, the renderer picks a supported effect.
        // Set the control to the current applied effect.
        if renderer.mfxScalingMode != currentScalingMode {
            scalingModeSegmentedControl.selectedSegmentIndex = renderer.mfxScalingMode.rawValue
        }
    }
}
