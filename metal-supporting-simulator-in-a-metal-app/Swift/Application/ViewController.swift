/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the view controller.
*/

#if os(macOS)
import Cocoa
typealias PlatformViewController = NSViewController
#else
import UIKit
typealias PlatformViewController = UIViewController
#endif
import MetalKit

class ViewController: PlatformViewController
{

    var renderer: Renderer!
    var mtkView: MTKView!

#if os(iOS)
    @IBOutlet weak var transparencySlider: UISlider!
    @IBOutlet weak var blendMode: UISegmentedControl!
#endif

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            print("View of Gameview controller is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }

        mtkView.device = defaultDevice
#if os(iOS) || os(tvOS)
        mtkView.backgroundColor = UIColor.black
#endif
        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        renderer.blendMode = BlendMode.transparency
        renderer.transparency = 0.5
        
        mtkView.delegate = renderer
    }
#if os(iOS)
    @IBAction func blendModeChanged(_ sender: UISegmentedControl) {
        let blendMode = BlendMode(rawValue: sender.selectedSegmentIndex)!
        renderer.blendMode = blendMode
        self.transparencySlider.isHidden = blendMode != BlendMode.transparency
    }
    @IBAction func transparencyChanged(_ sender: UISlider) {
        renderer.transparency = sender.value
    }
#endif
}
