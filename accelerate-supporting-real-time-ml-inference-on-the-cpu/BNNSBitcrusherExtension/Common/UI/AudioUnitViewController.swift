/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher view controller file.
*/

import Combine
import CoreAudioKit
import os
import SwiftUI

private let log = Logger(subsystem: "com.apple.BNNSBitcrusherExtension", category: "AudioUnitViewController")

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    
    var hostingController: HostingController<BNNSBitcrusherExtensionMainView>?
    
    private var observation: NSKeyValueObservation?

	/* iOS view lifcycle
	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Recreate any view-related resources here.
	}

	public override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		// Destroy any view-related content here.
	}
	*/

	/* macOS view lifcycle
	public override func viewWillAppear() {
		super.viewWillAppear()
		
		// Recreate any view-related resources here.
	}

	public override func viewDidDisappear() {
		super.viewDidDisappear()

		// Destroy any view-related content here.
	}
	*/

	deinit {
	}

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Accessing the `audioUnit` parameter prompts the system to create the audio unit with `createAudioUnit(with:)`.
        guard let audioUnit = self.audioUnit else {
            return
        }
        configureSwiftUIView(audioUnit: audioUnit)
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try BNNSBitcrusherExtensionAudioUnit(componentDescription: componentDescription, options: [])
        
        guard let audioUnit = self.audioUnit as? BNNSBitcrusherExtensionAudioUnit else {
            log.error("Unable to create BNNSBitcrusherExtensionAudioUnit")
            return audioUnit!
        }
        
        defer {
            // Configure the SwiftUI view after creating the audio unit, instead of in `viewDidLoad`,
            // so that the system sets up the parameter tree before building the `@AUParameterUI` properties.
            DispatchQueue.main.async {
                self.configureSwiftUIView(audioUnit: audioUnit)
            }
        }
        
        audioUnit.setupParameterTree(BNNSBitcrusherExtensionParameterSpecs.createAUParameterTree())
        
        self.observation = audioUnit.observe(\.allParameterValues, options: [.new]) { object, change in
            guard let tree = audioUnit.parameterTree else { return }

            // This ensures the audio unit gets initial values from the host.
            for param in tree.allParameters { param.value = param.value }
        }
        
        guard audioUnit.parameterTree != nil else {
            log.error("Unable to access AU ParameterTree")
            return audioUnit
        }
        
        return audioUnit
    }
    
    private func configureSwiftUIView(audioUnit: AUAudioUnit) {
        if let host = hostingController {
            host.removeFromParent()
            host.view.removeFromSuperview()
        }
        
        guard let observableParameterTree = audioUnit.observableParameterTree else {
            return
        }
        let content = BNNSBitcrusherExtensionMainView(parameterTree: observableParameterTree)
        let host = HostingController(rootView: content)
        self.addChild(host)
        host.view.frame = self.view.bounds
        self.view.addSubview(host.view)
        hostingController = host
        
        // Make sure the SwiftUI view fills the full area that the view controller provides.
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        host.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        host.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        host.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.view.bringSubviewToFront(host.view)
    }
    
}
