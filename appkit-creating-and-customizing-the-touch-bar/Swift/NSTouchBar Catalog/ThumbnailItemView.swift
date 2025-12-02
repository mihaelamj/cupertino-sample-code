/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSScrubberItemView class for thumbnail images.
*/

import Cocoa

class ThumbnailItemView: NSScrubberItemView {
    
    static let thumbnailCache = NSCache<NSString, NSImage>()
    
    private let imageView: NSImageView
    private let spinner: NSProgressIndicator
    
    private var thumbnail: NSImage {
        didSet {
            spinner.isHidden = true
            spinner.stopAnimation(nil)
            imageView.isHidden = false
            imageView.image = thumbnail
        }
    }
    
    var imageName: String? {
        didSet {
            guard oldValue != imageName else { return }
            guard let imageName = imageName else {
                imageView.image = nil
                return
            }
            
            if let cachedThumbnail = ThumbnailItemView.thumbnailCache.object(forKey: imageName as NSString) {
                thumbnail = cachedThumbnail
                return
            }
            
            spinner.isHidden = false
            spinner.startAnimation(nil)
            imageView.isHidden = true
            
            let currentName = imageName
            DispatchQueue.global(qos: .background).async {
                guard let fullImage = NSImage(named: currentName) else {
                    DispatchQueue.main.async {
                        if currentName == self.imageName {
                            self.thumbnail = NSImage(size: .zero)
                        }
                    }
                    
                    return
                }
                
                let imageSize = fullImage.size
                let thumbnailHeight: CGFloat = 30
                let thumbnailSize = NSSize(width: ceil(thumbnailHeight * imageSize.width / imageSize.height), height: thumbnailHeight)
                
                let thumbnail = NSImage(size: thumbnailSize)
                thumbnail.lockFocus()
                fullImage.draw(in: NSRect(origin: .zero, size: thumbnailSize),
                               from: NSRect(origin: .zero, size: imageSize),
                               operation: .sourceOver,
                               fraction: 1.0)
                thumbnail.unlockFocus()
                
                ThumbnailItemView.thumbnailCache.setObject(thumbnail, forKey: self.imageName! as NSString)
                
                DispatchQueue.main.async {
                    if currentName == self.imageName {
                        self.thumbnail = thumbnail
                    }
                }
            }
        }
    }
    
    required override init(frame frameRect: NSRect) {
        thumbnail = NSImage(size: frameRect.size)
        imageView = NSImageView(image: thumbnail)
        imageView.autoresizingMask = [.width, .height]
        spinner = NSProgressIndicator()
        
        super.init(frame: frameRect)
        
        spinner.isIndeterminate = true
        spinner.style = .spinning
        spinner.sizeToFit()
        spinner.frame = bounds.insetBy(dx: (bounds.width - spinner.frame.width) / 2, dy: (bounds.height - spinner.frame.height) / 2)
        spinner.isHidden = true
        spinner.controlSize = .small
        spinner.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        spinner.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxXMargin]
        
        subviews = [imageView, spinner]
    }
    
    required init?(coder: NSCoder) {
        // The system always creates this particular view class programmatically.
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayer() {
        layer?.backgroundColor = NSColor.controlColor.cgColor
    }
    
    override func layout() {
        super.layout()
        
        imageView.frame = bounds
        spinner.sizeToFit()
        spinner.frame = bounds.insetBy(dx: (bounds.width - spinner.frame.width) / 2, dy: (bounds.height - spinner.frame.height) / 2)
    }
    
}

