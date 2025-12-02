/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Stores the example drawings the app uses to update the model.
*/

import SwiftUI
import CoreML

/// - Tag: LabeledDrawingCollection
struct ExampleDrawingSet {
    
    /// The desired number of drawings to update the model
    private let requiredDrawingCount = 3
    
    /// Collection of the training drawings
    private var trainingDrawings = [UserDrawing]()

    /// The emoji or sticker that the model should predict when passed similar images
    let emoji: Character
    
    /// A Boolean that indicates whether the instance has all the required drawings.
    var isReadyForTraining: Bool { trainingDrawings.count == requiredDrawingCount }
    
    init(for emoji: Character) {
        self.emoji = emoji
    }
    
   /// Creates a batch provider of training data given the contents of `trainingDrawings`.
   /// - Tag: DrawingBatchProvider
    var featureBatchProvider: MLBatchProvider {
        var featureProviders = [MLFeatureProvider]()

        let inputName = "drawing"
        let outputName = "label"
                
        for drawing in trainingDrawings {
            let inputValue = drawing.featureValue
            let outputValue = MLFeatureValue(string: String(emoji))
            
            let dataPointFeatures: [String: MLFeatureValue] = [inputName: inputValue,
                                                               outputName: outputValue]
            
            if let provider = try? MLDictionaryFeatureProvider(dictionary: dataPointFeatures) {
                featureProviders.append(provider)
            }
        }
        
       return MLArrayBatchProvider(array: featureProviders)
   }
           
    /// Adds a drawing to the private array, but only if the type requires more.
    mutating func addDrawing(_ drawing: UserDrawing) {
        if trainingDrawings.count < requiredDrawingCount {
            trainingDrawings.append(drawing)
        }
    }
}
