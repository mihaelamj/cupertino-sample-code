/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ViewController to perform the Vision processing and handling the results.
*/

import UIKit
import Vision

class ResultsViewController: UIViewController {

    @IBOutlet var firstPlaceImageView: UIImageView!
    @IBOutlet var firstPlaceLabel: UILabel!
    @IBOutlet var secondPlaceImageView: UIImageView!
    @IBOutlet var secondPlaceLabel: UILabel!
    @IBOutlet var thirdPlaceImageView: UIImageView!
    @IBOutlet var thirdPlaceLabel: UILabel!
    
    let showDetailsSegueID = "ShowDetailsSegue"
    
    var originalImageURL: URL?
    var contestantImageURLs = [URL]()

    var ranking = [(contestantIndex: Int, featureprintDistance: Float)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        // Clear contestant labels.
        for label in [firstPlaceLabel, secondPlaceLabel, thirdPlaceLabel] {
            label?.text = ""
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.processImages()
        }
    }
    
    func processImages() {
        guard let originalURL = originalImageURL else {
            return
        }
        /// Generate feature print for original.
        /// - Tag: FeaturePrintOriginal
        // Generate a feature print for the original drawing.
        guard let originalFPO = featureprintObservationForImage(atURL: originalURL) else {
            return
        }
        /// Generate feature print for contestants.
        /// - Tag: FeaturePrintContestants
        // Generate feature prints for contestant images.
        // Next compute their distances from the original feature print.
        for idx in contestantImageURLs.indices {
            let contestantImageURL = contestantImageURLs[idx]
            if let contestantFPO = featureprintObservationForImage(atURL: contestantImageURL) {
                do {
                    var distance = Float(0)
                    try contestantFPO.computeDistance(&distance, to: originalFPO)
                    ranking.append((contestantIndex: idx, featureprintDistance: distance))
                } catch {
                    print("Error computing distance between featureprints.")
                }
            }
        }
        // Sort results based on distance.
        ranking.sort { (result1, result2) -> Bool in
            return result1.featureprintDistance < result2.featureprintDistance
        }
        DispatchQueue.main.async {
            self.presentResults()
        }
    }
    
    /// Calculate feature print observation.
    /// - Tag: FeaturePrintObservation
    func featureprintObservationForImage(atURL url: URL) -> VNFeaturePrintObservation? {
        let requestHandler = VNImageRequestHandler(url: url, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()
        do {
            try requestHandler.perform([request])
            return request.results?.first
        } catch {
            print("Vision error: \(error)")
            return nil
        }
    }
    
    func presentResults() {
        let viewPairs: [(imageView: UIImageView, label: UILabel)] = [(firstPlaceImageView, firstPlaceLabel),
                                                                     (secondPlaceImageView, secondPlaceLabel),
                                                                     (thirdPlaceImageView, thirdPlaceLabel)]
        
        UIView.animate(withDuration: 0.25) {
            for idx in viewPairs.indices {
                let viewPair = viewPairs[idx]
                guard idx < self.ranking.count else {
                    break
                }
                let result = self.ranking[idx]
                let imageURL = self.contestantImageURLs[result.contestantIndex]
                viewPair.imageView.image = UIImage(contentsOfFile: imageURL.path)
                viewPair.label.text = "Contestant \(result.contestantIndex + 1)"
            }
        }
    }
    
    @IBAction func done(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func returnToResults(_ segue: UIStoryboardSegue) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == showDetailsSegueID, let detailsVC = segue.destination as? DetailsViewController else {
            return
        }
        // Append original as a first node.
        detailsVC.nodes.append((url: originalImageURL, label: "Original", distance: 0))
        // Now append contestant images.
        for entry in ranking {
            let idx = entry.contestantIndex
            let url = contestantImageURLs[idx]
            detailsVC.nodes.append((url: url, label: "Contestant \(idx + 1)", distance: entry.featureprintDistance))
        }
    }
}

