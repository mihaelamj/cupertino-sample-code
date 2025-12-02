/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Key-value observing objects that monitor the state of AVCaptureDevice properties.
*/

import AVFoundation

class VideoEffectsObserver: NSObject, ObservableObject, @unchecked Sendable {
    
    let centerStageKeyPath = "centerStageEnabled"
    let portraitEffectKeyPath = "portraitEffectEnabled"
    let studioLightKeyPath = "studioLightEnabled"
    
    @Published private(set) var isCenterStageEnabled = false
    @Published private(set) var isPortraitEffectEnabled = false
    @Published private(set) var isStudioLightEnabled = false
    
    override init() {
        super.init()
        AVCaptureDevice.self.addObserver(self, forKeyPath: centerStageKeyPath, options: [.new], context: nil)
        AVCaptureDevice.self.addObserver(self, forKeyPath: portraitEffectKeyPath, options: [.new], context: nil)
        AVCaptureDevice.self.addObserver(self, forKeyPath: studioLightKeyPath, options: [.new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case centerStageKeyPath:
            isCenterStageEnabled = AVCaptureDevice.isCenterStageEnabled
        case portraitEffectKeyPath:
            isPortraitEffectEnabled = AVCaptureDevice.isPortraitEffectEnabled
        case studioLightKeyPath:
            isStudioLightEnabled = AVCaptureDevice.isStudioLightEnabled
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

class PreferredCameraObserver: NSObject, ObservableObject {
    
    private let systemPreferredKeyPath = "systemPreferredCamera"
    
    @Published private(set) var systemPreferredCamera: AVCaptureDevice?
    
    override init() {
        super.init()
        // Key-value observe the `systemPreferredCamera` class property on `AVCaptureDevice`.
        AVCaptureDevice.self.addObserver(self, forKeyPath: systemPreferredKeyPath, options: [.new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case systemPreferredKeyPath:
            // Update the observer's system-preferred camera value.
            systemPreferredCamera = change?[.newKey] as? AVCaptureDevice
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
