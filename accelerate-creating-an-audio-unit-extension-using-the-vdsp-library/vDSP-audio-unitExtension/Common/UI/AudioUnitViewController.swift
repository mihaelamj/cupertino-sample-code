/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit view controller file.
*/

import Combine
import CoreAudioKit
import os
import SwiftUI

private let log = Logger(subsystem: "com.apple.vDSP-audio-unitExtension", category: "AudioUnitViewController")

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    
    var hostingController: HostingController<vDSP_audio_unitExtensionMainView>?
    
    private var observation: NSKeyValueObservation?

	/* iOS view lifecycle.
	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Recreate any view-related resources here.
	}

	public override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		// Destroy any view-related content here.
	}
	*/

	/* macOS View lifcycle
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
        
        // Accessing the `audioUnit` parameter prompts the AU to be created via `createAudioUnit(with:)`.
        guard let audioUnit = self.audioUnit else {
            return
        }
        configureSwiftUIView(audioUnit: audioUnit)
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try vDSP_audio_unitExtensionAudioUnit(componentDescription: componentDescription, options: [])
        
        guard let audioUnit = self.audioUnit as? vDSP_audio_unitExtensionAudioUnit else {
            log.error("Unable to create vDSP_audio_unitExtensionAudioUnit")
            return audioUnit!
        }
        
        defer {
            // Configure the SwiftUI view after creating the AU, instead of in viewDidLoad,
            // so that the parameter tree is set up before the code builds the `@AUParameterUI` properties.
            DispatchQueue.main.async {
                self.configureSwiftUIView(audioUnit: audioUnit)
            }
        }
        
        audioUnit.setupParameterTree(vDSP_audio_unitExtensionParameterSpecs.createAUParameterTree())
        
        self.observation = audioUnit.observe(\.allParameterValues, options: [.new]) { object, change in
            guard let tree = audioUnit.parameterTree else { return }

            // This insures the audio unit gets initial values from the host.
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
        let content = vDSP_audio_unitExtensionMainView(parameterTree: observableParameterTree)
        let host = HostingController(rootView: content)
        self.addChild(host)
        host.view.frame = self.view.bounds
        self.view.addSubview(host.view)
        hostingController = host
        
        // Make sure the SwiftUI view fills the full area provided by the view controller.
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        host.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        host.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        host.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.view.bringSubviewToFront(host.view)
    }
    
}
