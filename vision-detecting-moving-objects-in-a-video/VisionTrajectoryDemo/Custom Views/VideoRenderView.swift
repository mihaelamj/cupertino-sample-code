/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that renders video file contents.
*/

import UIKit
import AVFoundation

protocol NormalizedRectConverting {
    func viewRectConverted(fromNormalizedContentsRect normalizedRect: CGRect) -> CGRect
}

class VideoRenderView: UIView, NormalizedRectConverting {
    
    // MARK: - Private Properties
    private var renderLayer: CALayer!
    
    // MARK: - Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        renderLayer = layer
        renderLayer.contentsGravity = .resizeAspect
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        renderLayer = layer
        renderLayer.contentsGravity = .resizeAspect
    }
    
    // MARK: - Public Methods
    
    func viewRectConverted(fromNormalizedContentsRect normalizedRect: CGRect) -> CGRect {
        guard let contents = renderLayer.contents else {
            return .zero
        }
        let image = contents as! CGImage
        let layerRect = renderLayer.bounds
        let imgHeight = CGFloat(image.height)
        let imgWidth = CGFloat(image.width)
        
        let imageTransform = CGAffineTransform(scaleX: imgWidth, y: imgHeight)
        let imgRect = normalizedRect.applying(imageTransform)
        
        let scaleToFit = min(layerRect.width / imgWidth, layerRect.height / imgHeight)
        let fitTransform = CGAffineTransform(scaleX: scaleToFit, y: scaleToFit)
        let scaledRect = imgRect.applying(fitTransform)
        
        let centerTransform = CGAffineTransform(translationX: (layerRect.width - imgWidth * scaleToFit) / 2,
                                                y: (layerRect.height - imgHeight * scaleToFit) / 2)
        let viewRect = scaledRect.applying(centerTransform)
        return viewRect.integral
    }
    
}
