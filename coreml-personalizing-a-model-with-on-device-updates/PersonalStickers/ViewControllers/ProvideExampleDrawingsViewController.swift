/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller that manages training a model.
*/

import UIKit

final class ProvideExampleDrawingsViewController: UIViewController {
    var exampleViewControllers = [ExampleDrawingViewController]()
    var exampleDrawings: ExampleDrawingSet!
    
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    
    @IBSegueAction func makeExampleDrawingViewController(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> ExampleDrawingViewController? {
        guard let exampleViewController = ExampleDrawingViewController(coder: coder) else {
            print("Unable to create StickerExampleViewController")
            return nil
        }
        
        exampleViewController.delegate = self
        exampleViewControllers.append(exampleViewController)
        return exampleViewController
    }
    
    @IBAction func doneBarButtonTapped(_ sender: UIBarButtonItem) {
        print("User tapped \"Done\"; kicking off model update...")
        
        // Convert the drawings into a batch provider as the update input.
        let drawingTrainingData = exampleDrawings.featureBatchProvider
        
        // Update the Drawing Classifier with the drawings.
        DispatchQueue.global(qos: .userInitiated).async {
            ModelUpdater.updateWith(trainingData: drawingTrainingData) {
                DispatchQueue.main.async { self.dismiss(animated: true, completion: nil) }
            }
        }
    }
}

extension ProvideExampleDrawingsViewController: DrawingDelegate {
    func didProduce(drawing: UserDrawing, sender: Any?) {
        DispatchQueue.main.async { self.addDrawing(drawing) }
    }
    
    func addDrawing(_ drawing: UserDrawing) {
        exampleDrawings.addDrawing(drawing)
        doneBarButton.isEnabled = exampleDrawings.isReadyForTraining
    }
}
