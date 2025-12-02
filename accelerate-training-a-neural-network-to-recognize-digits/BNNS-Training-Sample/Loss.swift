/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Constants, descriptors, and functions for the loss layer.
*/

import Accelerate

extension TrainingSample {
    
    // MARK: Input, Output, and Parameter Descriptorss
    
    // This sample reduces loss to a single value.
    static let lossOutputWidth = 1
    
    static let lossOutput = BNNSNDArrayDescriptor.allocateUninitialized(
        scalarType: Float.self,
        shape: .vector(lossOutputWidth))
    
    // MARK: Layer Creation
    
    static var lossLayer: BNNS.LossLayer = {
        
        guard let lossLayer = BNNS.LossLayer(input: fullyConnectedOutput,
                                             output: lossOutput,
                                             lossFunction: .softmaxCrossEntropy(labelSmoothing: 0),
                                             lossReduction: .reductionMean,
                                             filterParameters: filterParameters) else {
            fatalError("Unable to create `lossLayer`.")
        }
        
        return lossLayer
    }()
    
    // MARK: Compute Loss Function
    
    static func computeLoss() {
        do {
            try lossLayer.apply(batchSize: batchSize,
                                input: fullyConnectedOutput,
                                labels: oneHotLabels,
                                output: lossOutput,
                                generatingInputGradient: lossInputGradient)
        } catch {
            fatalError("`loss()` failed.")
        }
    }
    
    // MARK: Gradient Descriptors
    
    static let lossInputGradient = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: .vector(fullyConnectedOutputWidth),
        batchSize: batchSize)
}
