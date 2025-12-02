/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The macOS SaliencyViewController contains methods that implement view related logic and visualization of the results
*/

import Cocoa
import Vision

class SaliencyViewController: NSViewController, NSMenuItemValidation, NSWindowDelegate {

    @IBOutlet weak var dragImageLabel: NSTextField!

    func processImage() {
        guard let imgURL = imageURL else {
            if let bundleName = Bundle.main.infoDictionary?[String(kCFBundleNameKey)] as? String {
                view.window?.title = bundleName
            }
            return
        }
        view.window?.title = imgURL.lastPathComponent
        guard let saliencyType = SaliencyType(rawValue: saliencyTypeRawValue) else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.observation = processSaliency(saliencyType, on: imgURL)
        }
    }
    
    var imageURL: URL? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.dragImageLabel.isHidden = true
                self?.processImage()
            }
        }
    }
    
    var observation: VNSaliencyImageObservation? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateLayersContent()
            }
        }
    }
    
    let imageLayer = CALayer()
    let salientObjectsLayer = CAShapeLayer()
    let saliencyMaskLayer = CALayer()
    
    let saliencyTypeDefaultsKey = "SaliencyType"
    @objc dynamic var saliencyTypeRawValue: Int {
        get {
            return UserDefaults.standard.integer(forKey: saliencyTypeDefaultsKey)
        }
        set {
            willChangeValue(for: \.saliencyTypeRawValue)
            UserDefaults.standard.set(newValue, forKey: saliencyTypeDefaultsKey)
            didChangeValue(for: \.saliencyTypeRawValue)
            processImage()
        }
    }
    
    let viewModeDefaultsKey = "ViewMode"
    @objc var viewModeRawValue: Int {
        get {
            return UserDefaults.standard.integer(forKey: viewModeDefaultsKey)
        }
        set {
            willChangeValue(for: \.viewModeRawValue)
            UserDefaults.standard.set(newValue, forKey: viewModeDefaultsKey)
            didChangeValue(for: \.viewModeRawValue)
            updateLayersVisibility()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register default values.
        let userDefaults = UserDefaults.standard
        userDefaults.register(defaults: [
            saliencyTypeDefaultsKey: SaliencyType.attentionBased.rawValue,
            viewModeDefaultsKey: ViewMode.combined.rawValue])
        // Setup layers.
        if let baseLayer = view.layer {
            baseLayer.addSublayer(imageLayer)
            baseLayer.addSublayer(saliencyMaskLayer)
            baseLayer.addSublayer(salientObjectsLayer)
            salientObjectsLayer.strokeColor = #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1)
            salientObjectsLayer.fillColor = nil
        }
        updateLayersVisibility()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if let window = view.window {
            window.registerForDraggedTypes([.URL])
            window.delegate = self
        }
    }
    
    override func viewDidLayout() {
        updateLayersGeometry()
        super.viewDidLayout()
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(setSaliencyType(_:)):
            menuItem.state = (menuItem.tag == saliencyTypeRawValue) ? .on : .off
        case #selector(setViewMode(_:)):
            menuItem.state = (menuItem.tag == viewModeRawValue) ? .on : .off
        default:
            break
        }
        return true
    }

    func updateLayersContent() {
        guard let imgURL = imageURL else {
            imageLayer.contents = nil
            salientObjectsLayer.path = nil
            saliencyMaskLayer.contents = nil
            return
        }

        imageLayer.contents = NSImage(contentsOf: imgURL)
        updateLayersGeometry()
        
        if let observation = observation {
            saliencyMaskLayer.contents = createHeatMapMask(from: observation)
            
            // Transform to convert from normalized coordinates to layer's coordinates.
            let pathT = CGAffineTransform(scaleX: salientObjectsLayer.bounds.width, y: salientObjectsLayer.bounds.height)
            let path = createSalientObjectsBoundingBoxPath(from: observation, transform: pathT)
            salientObjectsLayer.path = path
        } else {
            saliencyMaskLayer.contents = nil
            salientObjectsLayer.path = nil
        }
    }
    
    func updateLayersGeometry() {
        if let baseLayer = view.layer {
            let imgSize = (imageLayer.contents as? NSImage)?.size ?? NSSize.zero
            let fitScale = min(baseLayer.bounds.width / imgSize.width, baseLayer.bounds.height / imgSize.height)
            let scaleT = CGAffineTransform(scaleX: fitScale, y: fitScale)
            // Change sublayer's frames without animation.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            for layer in [imageLayer, salientObjectsLayer, saliencyMaskLayer] {
                layer.bounds = CGRect(x: 0, y: 0, width: imgSize.width, height: imgSize.height)
                layer.position = CGPoint(x: baseLayer.bounds.width / 2, y: baseLayer.bounds.height / 2)
                layer.setAffineTransform(scaleT)
            }
            salientObjectsLayer.lineWidth = 1 / fitScale
            CATransaction.commit()
        }
    }
    
    func updateLayersVisibility() {
        guard let mode = ViewMode(rawValue: viewModeRawValue) else {
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
    
    // MARK: - Actions
    @IBAction func setSaliencyType(_ sender: NSMenuItem) {
        guard let type = SaliencyType(rawValue: sender.tag) else {
            print("Unknown saliency type: \(sender.tag)")
            return
        }
        saliencyTypeRawValue = type.rawValue
    }
    
    @IBAction func setViewMode(_ sender: NSMenuItem) {
        guard let mode = ViewMode(rawValue: sender.tag) else {
            print("Unknown view mode: \(sender.tag)")
            return
        }
        viewModeRawValue = mode.rawValue
    }
    
    @IBAction func openImage(_ sender: NSMenuItem) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose an Image"
        openPanel.allowedFileTypes = ["public.image"]
        openPanel.beginSheetModal(for: view.window!) { (response) in
            if response == .OK {
                self.imageURL = openPanel.urls.first
            }
        }
    }
}

// MARK: - Drag and Drop

extension SaliencyViewController: NSDraggingDestination {
    var filteringOptions: [NSPasteboard.ReadingOptionKey: Any] {
        return [.urlReadingContentsConformToTypes: NSImage.imageTypes]
    }
    
    func shouldAccept(_ dragInfo: NSDraggingInfo) -> Bool {
        var acceptableDrag = false
        if dragInfo.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: filteringOptions) {
            acceptableDrag = true
        }
        return acceptableDrag
    }
    
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if shouldAccept(sender) {
            view.layer?.backgroundColor = NSColor.lightGray.cgColor
            return NSDragOperation.copy
        } else {
            return NSDragOperation()
        }
    }
    
    func draggingExited(_ sender: NSDraggingInfo?) {
        view.layer?.backgroundColor = nil
    }
    
    func draggingEnded(_ sender: NSDraggingInfo) {
        view.layer?.backgroundColor = nil
    }
    
    func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return shouldAccept(sender)
    }
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let dpb = sender.draggingPasteboard
        guard let urls = dpb.readObjects(forClasses: [NSURL.self], options: filteringOptions) as? [URL], !urls.isEmpty else {
            return false
        }
        imageURL = urls.first
        return true
    }
}
