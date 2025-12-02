/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The iOS SaliencyViewController contains methods that implement view related logic and visualization of the results
*/

import UIKit
import AVFoundation
import Vision

class SaliencyViewController: UIViewController {

    var observation: VNSaliencyImageObservation? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateLayersContent()
            }
        }
    }

    func processPixelBuffer(_ buffer: CVPixelBuffer) {
        observation = processSaliency(SaliencyType(rawValue: UserDefaults.standard.saliencyType)!, on: buffer, orientation: .right)
    }

    func updateLayersContent() {
        if let observation = self.observation {
            DispatchQueue.global(qos: .userInteractive).async {
                let path = createSalientObjectsBoundingBoxPath(from: observation, transform: self.salientObjectsPathTransform)
                DispatchQueue.main.async {
                    self.salientObjectsLayer.path = path
                }
                
                let mask = createHeatMapMask(from: observation)
                DispatchQueue.main.async {
                    self.saliencyMaskLayer.contents = mask
                }
            }
        }
    }

    func updateLayersGeometry() {
        if let baseLayer = videoLayer {
            // Align saliency mask and objects layers with video content rect -
            // depending on video gravity it is not necessarily equal to video layer's bounds.
            let outputRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            let videoRect = baseLayer.layerRectConverted(fromMetadataOutputRect: outputRect)
            saliencyMaskLayer.frame = videoRect
            salientObjectsLayer.frame = videoRect
            // transform to convert from normalized coordinates to layer's coordinates
            let scaleT = CGAffineTransform(scaleX: salientObjectsLayer.bounds.width, y: -salientObjectsLayer.bounds.height)
            let translateT = CGAffineTransform(translationX: 0, y: salientObjectsLayer.bounds.height)
            salientObjectsPathTransform = scaleT.concatenating(translateT)
        }
    }
    
    func updateLayersVisibility() {
        guard let mode = ViewMode(rawValue: UserDefaults.standard.viewMode) else {
            return
        }
        let saliencyMaskOpacity: Float!
        switch mode {
        case .combined:
            saliencyMaskOpacity = 0.75
        case .maskOnly:
            saliencyMaskOpacity = 1
        case .rectsOnly:
            saliencyMaskOpacity = 0
        }
        saliencyMaskLayer.opacity = saliencyMaskOpacity
    }
    
    @IBOutlet var viewModeToggle: UISegmentedControl!
    @IBOutlet var saliencyTypeToggle: UISegmentedControl!
    
    var session: AVCaptureSession?
    var videoLayer: AVCaptureVideoPreviewLayer?
    let salientObjectsLayer = CAShapeLayer()
    let saliencyMaskLayer = CALayer()
    var salientObjectsPathTransform = CGAffineTransform.identity
    
    var viewModeObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        
        guard let newSession = session else {
            fatalError("Error creating AVCaptureSession")
        }
        
        // Register default values.
        let userDefaults = UserDefaults.standard
        userDefaults.register(defaults: [
            userDefaults.saliencyTypeKey: SaliencyType.attentionBased.rawValue,
            userDefaults.viewModeKey: ViewMode.combined.rawValue])

        let layer = AVCaptureVideoPreviewLayer(session: newSession)
        layer.frame = view.layer.bounds
        layer.videoGravity = .resizeAspectFill
        layer.addSublayer(saliencyMaskLayer)
        salientObjectsLayer.strokeColor = #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1)
        salientObjectsLayer.fillColor = nil
        layer.addSublayer(salientObjectsLayer)
        view.layer.addSublayer(layer)
        videoLayer = layer
        updateLayersVisibility()
        
        // Set default values for toolbar items.
        viewModeToggle.selectedSegmentIndex = userDefaults.viewMode
        saliencyTypeToggle.selectedSegmentIndex = userDefaults.saliencyType

        // Observe defaults value changes.
        viewModeObserver = userDefaults.observe(\.viewMode) { _, _ in
            self.updateLayersVisibility()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        session?.startRunning()
        view.setNeedsLayout()
    }
    
    override func viewDidLayoutSubviews() {
        updateLayersGeometry()
        super.viewDidLayoutSubviews()
    }
    
    deinit {
        viewModeObserver?.invalidate()
        session?.stopRunning()
        videoLayer?.removeFromSuperlayer()
    }

    func setupCaptureSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            fatalError("Error getting AVCaptureDevice.")
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            fatalError("Error getting AVCaptureDeviceInput")
        }
        
        session = AVCaptureSession()
        session?.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        session?.addOutput(output)
    }
    
    // MARK: - Actions
    @IBAction func setSaliencyType(_ sender: UISegmentedControl) {
        guard let type = SaliencyType(rawValue: sender.selectedSegmentIndex) else {
            print("Unknown saliency type: \(sender.selectedSegmentIndex)")
            return
        }
        UserDefaults.standard.saliencyType = type.rawValue
    }
    
    @IBAction func setViewMode(_ sender: UISegmentedControl) {
        guard let mode = ViewMode(rawValue: sender.selectedSegmentIndex) else {
            print("Unknown view mode: \(sender.selectedSegmentIndex)")
            return
        }
        UserDefaults.standard.viewMode = mode.rawValue
    }
}

extension SaliencyViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        processPixelBuffer(pixelBuffer)
    }
}

extension UserDefaults {
    var saliencyTypeKey: String {
        return "SaliencyType"
    }
    
    @objc var saliencyType: Int {
        get {
            return integer(forKey: saliencyTypeKey)
        }
        set {
            set(newValue, forKey: saliencyTypeKey)
        }
    }
    
    var viewModeKey: String {
        return "ViewMode"
    }

    @objc var viewMode: Int {
        get {
            return integer(forKey: viewModeKey)
        }
        set {
            set(newValue, forKey: viewModeKey)
        }
    }
}
