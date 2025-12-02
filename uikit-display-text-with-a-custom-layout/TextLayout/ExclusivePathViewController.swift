/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that maintains an exclusive path for a text view.
*/

import UIKit

class ExclusivePathViewController: BaseViewController {

    @IBOutlet weak var imageView: UIImageView!
    private var kvoContentOffset: NSKeyValueObservation?
    private var kvoTextViewPosition: NSKeyValueObservation?
    private var panInitialImageCenter = CGPoint()

    private lazy var circlePath: UIBezierPath = {
        return UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 100, height: 100))
    }()
    
    private var translatedCirclePath: UIBezierPath {
        guard textView != nil else {
            fatalError("Failed to unwrap textView when creating translated circle path.")
        }
        guard let translatedPath = circlePath.copy() as? UIBezierPath else {
            fatalError("Failed to copy the bezier path.")
        }
        let originInTextView = textView.convert(imageView.frame.origin, from: view)
        let originInContainer = CGPoint(x: originInTextView.x - textView.textContainerInset.left,
                                        y: originInTextView.y - textView.textContainerInset.top)
        translatedPath.apply(CGAffineTransform(translationX: originInContainer.x, y: originInContainer.y))
        return translatedPath
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a UITextView instance with a custom text container.
        //
        let textContainer = NSTextContainer(size: .zero)
        textContainer.widthTracksTextView = true

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textView = UITextView(frame: CGRect.zero, textContainer: textContainer)
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.keyboardDismissMode = .interactive
        
        view.insertSubview(textView, belowSubview: imageView)

        // Set up image for imageView.
        //
        let size = circlePath.bounds.size
        imageView.frame.size = size
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.systemTeal.set()
        circlePath.fill()
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Set up Auto Layout constraints.
        //
        textView.translatesAutoresizingMaskIntoConstraints = false
        let safeAreaGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor)
        ])

        // Observe textView.contentOffset to synchronize the imageView's center
        // so that the imageView follows the text view content scrolling.
        //
        kvoContentOffset = observe(\.textView.contentOffset, options: [.old, .new]) { _, change in
            guard let oldValue = change.oldValue, let newValue = change.newValue,
                newValue.y != oldValue.y else {
                return
            }
            let center = self.imageView.center
            self.imageView.center = CGPoint(x: center.x, y: center.y + oldValue.y - newValue.y)
        }
        
        // Observe textView.layer.position to synchronize the imageView's center
        // so that the imageView follows textView position changes.
        //
        kvoTextViewPosition = observe(\.textView.layer.position) { _, _ in
            guard let pathBounds = self.textView.textContainer.exclusionPaths.first?.bounds else {
                return
            }
            let pathCenter = CGPoint(x: pathBounds.midX, y: pathBounds.midY)
            let pathCenterInTextView = CGPoint(x: pathCenter.x + self.textView.textContainerInset.left,
                                               y: pathCenter.y + self.textView.textContainerInset.top)
            let translatedCenter = self.textView.convert(pathCenterInTextView, to: self.textView.superview)
            self.imageView.center = translatedCenter
        }
    }

    // Set up the exclusive path for textView after laying out the textView.
    //
    override func viewDidLayoutSubviews() {
        if textView.textContainer.exclusionPaths.isEmpty {
            textView.textContainer.exclusionPaths = [translatedCirclePath]
        }
    }

    // Update the textContainer.exclusionPaths when the imageView moves.
    //
    @IBAction func imagePanned(_ sender: Any) {
        guard let pan = sender as? UIPanGestureRecognizer else { return }
        switch pan.state {
        case .began:
            panInitialImageCenter = imageView.center
        case .changed:
            let panCurrentTranslation = pan.translation(in: textView)
            imageView.center = CGPoint(x: panInitialImageCenter.x + panCurrentTranslation.x,
                                       y: panInitialImageCenter.y + panCurrentTranslation.y)
            textView.textContainer.exclusionPaths = [translatedCirclePath]
        default: return
        }
    }
}
