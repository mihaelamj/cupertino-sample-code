/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the image canvas for the meme generator.
*/

import Cocoa

/// Delegate for handling dragging events.
@objc protocol ImageCanvasDelegate: AnyObject {
    func draggingEntered(forImageCanvas imageCanvas: ImageCanvas, sender: NSDraggingInfo) -> NSDragOperation
    func performDragOperation(forImageCanvas imageCanvas: ImageCanvas, sender: NSDraggingInfo) -> Bool
    func pasteboardWriter(forImageCanvas imageCanvas: ImageCanvas) -> NSPasteboardWriting
}

/// View holding one base image and many user-editable text labels.
class ImageCanvas: NSView, NSTextFieldDelegate, NSDraggingSource {

    /// Used to represent the content of the canvas and render a flattened image.
    class SnapshotItem {
        let baseImage: NSImage
        let pixelSize: CGSize
        let drawingItems: [TextField.DrawingItem]
        let drawingScale: CGFloat

        init(baseImage: NSImage, pixelSize: CGSize, drawingItems: [TextField.DrawingItem], drawingScale: CGFloat) {
            self.baseImage = baseImage
            self.pixelSize = pixelSize
            self.drawingItems = drawingItems
            self.drawingScale = drawingScale
        }
        
        var outputImage: NSImage {
            return NSImage(size: pixelSize, flipped: false) { (rect) -> Bool in
                self.baseImage.draw(in: rect)
                let transform = NSAffineTransform()
                transform.scale(by: self.drawingScale)
                transform.concat()
                for drawingItem in self.drawingItems {
                    drawingItem.draw()
                }
                return true
            }
        }
        
        var jpegRepresentation: Data? {
            guard let tiffData = outputImage.tiffRepresentation else { return nil }
            let bitmapImageRep = NSBitmapImageRep(data: tiffData)
            return bitmapImageRep?.representation(using: .jpeg, properties: [:])
        }
    }
    
    var isHighlighted: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    var isLoading: Bool = false {
        didSet {
            imageView.isEnabled = !isLoading
            progressIndicator.isHidden = !isLoading
            if isLoading {
                progressIndicator.startAnimation(nil)
            } else {
                progressIndicator.stopAnimation(nil)
            }
        }
    }

    var image: NSImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            if let imageRep = newValue?.representations.first {
                imagePixelSize = CGSize(width: imageRep.pixelsWide, height: imageRep.pixelsHigh)
            }
            isLoading = false
            needsLayout = true
        }
    }
    
    var imageDescription: String {
        return (image != nil) ? "\(Int(imagePixelSize.width)) × \(Int(imagePixelSize.height))" : "..."
    }
    
    var draggingImage: NSImage {
        let targetRect = overlay.frame
        let image = NSImage(size: targetRect.size)
        if let imageRep = bitmapImageRepForCachingDisplay(in: targetRect) {
            cacheDisplay(in: targetRect, to: imageRep)
            image.addRepresentation(imageRep)
        }
        return image
    }
    
    var snapshotItem: SnapshotItem? {
        guard let image = image else { return nil }
        let drawingItems = textFields.map { $0.drawingItem }
        let drawingScale = imagePixelSize.width / overlay.frame.width
        return SnapshotItem(baseImage: image, pixelSize: imagePixelSize, drawingItems: drawingItems, drawingScale: drawingScale)
    }

    private let dragThreshold: CGFloat = 3.0
    private var dragOriginOffset = CGPoint.zero
    private var imagePixelSize = CGSize.zero

    @IBOutlet weak var delegate: ImageCanvasDelegate?
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var imageView: NSImageView!

    private var overlay: NSView!
    private var textFields = [TextField]()
    private var selectedTextField: TextField?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.unregisterDraggedTypes()
        progressIndicator.isHidden = true // Explicitly hiding the indicator in order not to catch mouse events.
        
        overlay = NSView()
        addSubview(overlay)
    }
    
    func addTextField() {
        let textField = TextField()
        textFields.append(textField)
        overlay.addSubview(textField)
        textField.delegate = self
        textField.centerInSuperview()
        textField.makeFirstResponder()
    }
    
    @IBAction func delete(_ sender: Any?) {
        if let textField = selectedTextField, let index = textFields.firstIndex(of: textField) {
            textFields.remove(at: index)
            selectedTextField?.removeFromSuperview()
            selectedTextField = nil
        }
    }
    
    private func rectForDrawingImage(with imageSize: CGSize, scaling: NSImageScaling) -> CGRect {
        var drawingRect = CGRect(origin: .zero, size: imageSize)
        let containerRect = bounds
        guard imageSize.width > 0 && imageSize.height > 0 else {
            return drawingRect
        }
        
        func scaledSizeToFitFrame() -> CGSize {
            var scaledSize = CGSize.zero
            let horizontalScale = containerRect.width / imageSize.width
            let verticalScale = containerRect.height / imageSize.height
            let minimumScale = min(horizontalScale, verticalScale)
            scaledSize.width = imageSize.width * minimumScale
            scaledSize.height = imageSize.height * minimumScale
            return scaledSize
        }
        
        switch scaling {
        case .scaleProportionallyDown:
            if imageSize.width > containerRect.width || imageSize.height > containerRect.height {
                drawingRect.size = scaledSizeToFitFrame()
            }
        case .scaleAxesIndependently:
            drawingRect.size = containerRect.size
        case .scaleProportionallyUpOrDown:
            if imageSize.width > 0.0 && imageSize.height > 0.0 {
                drawingRect.size = scaledSizeToFitFrame()
            }
        case .scaleNone:
            break
        default: break
        }
        
        drawingRect.origin.x = containerRect.minX + (containerRect.width - drawingRect.width) * 0.5
        drawingRect.origin.y = containerRect.minY + (containerRect.height - drawingRect.height) * 0.5
        
        return drawingRect
    }

    private func constrainRectCenterToBounds(_ rect: CGRect) -> CGRect {
        var result = rect
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        if center.x < 0.0 {
            result.origin.x = -(rect.width * 0.5)
        }
        
        if center.y < 0.0 {
            result.origin.y = -(rect.height * 0.5)
        }
        
        if center.x > overlay.bounds.width {
            result.origin.x = bounds.width - (rect.width * 0.5)
        }
        
        if center.y > overlay.bounds.height {
            result.origin.y = bounds.height - (rect.height * 0.5)
        }
        
        return backingAlignedRect(result, options: .alignAllEdgesNearest)
    }
    
    // MARK: - NSView
    
    override func hitTest(_ point: CGPoint) -> NSView? {
        var hitView = super.hitTest(point)
        // catching all mouse events except when editing text
        if hitView != window?.fieldEditor(false, for: nil) {
            hitView = self
        }
        return hitView
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let hitPoint = convert(location, to: superview)
        let hitView = super.hitTest(hitPoint)
        for textField in textFields {
            textField.isSelected = (hitView == textField)
        }
        
        let eventMask: NSEvent.EventTypeMask = [.leftMouseUp, .leftMouseDragged]
        let timeout = NSEvent.foreverDuration
        selectedTextField = hitView as? TextField
        if let textField = selectedTextField {
            // drag the text field
            let textFrame = textField.frame
            dragOriginOffset = CGPoint(x: location.x - textFrame.minX, y: location.y - textFrame.minY)
            
            if event.clickCount == 2 {
                textField.isSelected = false
                window?.makeFirstResponder(textField)
            } else {
                window?.trackEvents(matching: eventMask, timeout: timeout, mode: .eventTracking, handler: { (event, stop) in
                    guard let event = event else { return }

                    if event.type == .leftMouseUp {
                        stop.pointee = true
                    }
                    
                    let movedLocation = convert(event.locationInWindow, from: nil)
                    let movedOrigin = CGPoint(x: movedLocation.x - dragOriginOffset.x, y: movedLocation.y - dragOriginOffset.y)
                    textField.frame = constrainRectCenterToBounds(CGRect(origin: movedOrigin, size: textFrame.size))
                })
            }
        } else if image != nil {
            // Drag the flattened image.
            window?.trackEvents(matching: eventMask, timeout: timeout, mode: .eventTracking, handler: { (event, stop) in
                guard let event = event else { return }
                
                if event.type == .leftMouseUp {
                    stop.pointee = true
                } else {
                    let movedLocation = convert(event.locationInWindow, from: nil)
                    if abs(movedLocation.x - location.x) > dragThreshold || abs(movedLocation.y - location.y) > dragThreshold {
                        stop.pointee = true
                        if let delegate = delegate {
                            let draggingItem = NSDraggingItem(pasteboardWriter: delegate.pasteboardWriter(forImageCanvas: self))
                            draggingItem.setDraggingFrame(overlay.frame, contents: draggingImage)
                            beginDraggingSession(with: [draggingItem], event: event, source: self)
                        }
                    }
                }
            })
        }
    }
    
    override func layout() {
        super.layout()
        
        let imageSize = image?.size ?? .zero
        overlay.frame = rectForDrawingImage(with: imageSize, scaling: imageView.imageScaling)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if isHighlighted {
            NSGraphicsContext.saveGraphicsState()
            NSFocusRingPlacement.only.set()
            bounds.insetBy(dx: 2, dy: 2).fill()
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    // MARK: - NSTextViewDelegate
    
    func controlTextDidEndEditing(_ obj: Notification) {
        window?.makeFirstResponder(self)
    }
    
    // MARK: - NSDraggingSource
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return (context == .outsideApplication) ? [.copy] : []
    }
    
    // MARK: - NSDraggingDestination
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        var result: NSDragOperation = []
        if let delegate = delegate {
            result = delegate.draggingEntered(forImageCanvas: self, sender: sender)
            isHighlighted = (result != [])
        }
        return result
    }
        
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return delegate?.performDragOperation(forImageCanvas: self, sender: sender) ?? true
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isHighlighted = false
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        isHighlighted = false
    }
    
}
