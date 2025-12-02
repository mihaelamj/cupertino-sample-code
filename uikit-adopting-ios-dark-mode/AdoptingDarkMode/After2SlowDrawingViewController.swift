/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller demonstrating doing time-consuming drawing on a background thread.
 This is the code after dark mode adoption has happened.
*/

import UIKit

class After2SlowDrawingViewController: UIViewController {

    // This view controller will draw an image, off of the main thread,
    // and display the results in resultImageView.
    @IBOutlet var resultImageView: UIImageView!

    // While it's drawing, it shows an activity indicator (spinner).
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // DARK MODE ADOPTION: Changed to use a new iOS 13 activity
        // indicator style which appears correct in light and dark modes.
        activityIndicator.style = .large
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // After our view has appeared, start performing the
        // slow drawing operation.

        performSlowDrawing()
    }

    func performSlowDrawing() {
        // On the main queue:
        // Start the spinner.
        activityIndicator.startAnimating()

        // Determine how big the image should be.
        let size = resultImageView.bounds.size

        // Specify what colors to draw.
        // DARK MODE ADOPTION: Use some dynamic colors which appear
        // different in light and dark mode.
        let colors: [UIColor] = [ .systemBackground, .secondarySystemBackground, .gray, UIColor(named: "LightAndDarkHeaderColor")! ]

        // DARK MODE ADOPTION: Our trait collection will be used
        // to determine the appearance of dynamic colors. Pass it
        // to the drawing code.
        let traitCollection = self.traitCollection

        // Perform this work off of the main queue.
        DispatchQueue.global(qos: .userInitiated).async {
            var image: UIImage?

            // DARK MODE ADOPTION: Sets the provided trait collection
            // as current, so that when we draw using dynamic colors,
            // the colors are resolved based on those traits.
            traitCollection.performAsCurrent {
                image = self.createImage(size, colors)
            }

            // And go back to the main queue to update the UI.
            DispatchQueue.main.async {
                self.resultImageView.image = image
                self.activityIndicator.stopAnimating()
            }
        }
    }

    func createImage(_ size: CGSize, _ colors: [UIColor]) -> UIImage {
        // Perform some time-consuming drawing, using some colors of our choice.
        // This example just draws a lot of random circles.

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context: UIGraphicsImageRendererContext) in
            for _ in 0...25_000 {
                let colorIndex = Int.random(in: 0..<colors.count)
                let color = colors[colorIndex]
                color.setFill()

                let rectX = CGFloat.random(in: 0..<size.width)
                let rectY = CGFloat.random(in: 0..<size.height)
                let size = CGFloat.random(in: 0..<80)

                let rect = CGRect(x: rectX, y: rectY, width: size, height: size)
                let path = UIBezierPath(ovalIn: rect)
                path.fill()
            }
        }
    }

    // DARK MODE ADOPTION: When a trait change happens that could affect
    // colors, re-create the image using the new traits.

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if resultImageView.image != nil {
                resultImageView.image = nil
                performSlowDrawing()
            }
        }
    }

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
