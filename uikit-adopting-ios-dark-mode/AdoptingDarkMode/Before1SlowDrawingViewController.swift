/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller demonstrating doing time-consuming drawing on a background thread.
 This is the code before dark mode adoption has happened.
*/

import UIKit

class Before1SlowDrawingViewController: UIViewController {

    // This view controller will draw an image, off of the main thread,
    // and display the results in resultImageView.
    @IBOutlet var resultImageView: UIImageView!

    // While it's drawing, it shows an activity indicator (spinner).
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

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
        let colors: [UIColor] = [ .white, .lightGray, .gray, UIColor(named: "HeaderColor")! ]

        // Perform this work off of the main queue.
        DispatchQueue.global(qos: .userInitiated).async {
            let image = self.createImage(size, colors)

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

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}

