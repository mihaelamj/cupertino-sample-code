/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that draws the gradient and text string representing a feed entry.
*/

import UIKit

class ColorView: UIView {
    struct Parameters: Equatable {
        let firstColor: UIColor
        let secondColor: UIColor
        let gradientDirection: Double
        let text: String?
    }

    var parameters: Parameters? {
        didSet {
            if oldValue != parameters {
                updateContents(resetExisting: true)
            }
        }
    }

    private func updateContents(resetExisting: Bool = false) {
        queue.cancelAllOperations()
        
        if resetExisting || parameters == nil {
            setImage(image: nil, animated: false)
        }
        
        guard let parameters = parameters else { return }
        
        let rect = bounds
        let operation = BlockOperation()
        
        operation.addExecutionBlock() { [weak self, weak operation] in
            guard let self = self, let operation = operation, !operation.isCancelled else {
                return
            }
            
            let image = self.render(parameters: parameters, in: rect)
            DispatchQueue.main.async() {
                guard !operation.isCancelled else { return }
                
                self.setImage(image: image, animated: true)
            }
        }
        
        queue.addOperation(operation)
    }

    private let imageView = UIImageView()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(imageView)
    }
    
    private func setImage(image: UIImage?, animated: Bool) {
        guard animated else {
            imageView.image = image
            return
        }
        
        UIView.transition(with: imageView,
                          duration: 0.2,
                          options: [.transitionCrossDissolve, .beginFromCurrentState, .allowUserInteraction],
                          animations: {
            self.imageView.image = image
        }, completion: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        updateContents()
    }
    
    private func render(parameters: Parameters, in rect: CGRect) -> UIImage {
        return UIGraphicsImageRenderer(size: rect.size).image() { _ in
            guard let context = UIGraphicsGetCurrentContext() else { return }
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [parameters.firstColor.cgColor,
                                               parameters.secondColor.cgColor] as CFArray,
                                      locations: [0, 1])!
            
            let angle = parameters.gradientDirection / 360.0
            
            let startX = pow(sin(2 * .pi * (0.75 + angle) / 2), 2) * Double(rect.width)
            let startY = pow(sin(2 * .pi * angle / 2), 2) * Double(rect.height)
            
            let endX = pow(sin(2 * .pi * (0.25 + angle) / 2), 2) * Double(rect.width)
            let endY = pow(sin(2 * .pi * (0.5 + angle) / 2), 2) * Double(rect.height)
            
            context.drawLinearGradient(gradient,
                                       start: CGPoint(x: startX, y: startY),
                                       end: CGPoint(x: endX, y: endY),
                                       options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            
            if let text = parameters.text {
                context.setBlendMode(.screen)
                
                let font = UIFont.systemFont(ofSize: 48, weight: .bold)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let drawBounds = rect.insetBy(dx: 0, dy: (rect.height - font.pointSize) / 2)
                NSAttributedString(string: text, attributes: [
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5),
                    .font: font
                    ]).draw(in: drawBounds)
            }
        }
    }
}
