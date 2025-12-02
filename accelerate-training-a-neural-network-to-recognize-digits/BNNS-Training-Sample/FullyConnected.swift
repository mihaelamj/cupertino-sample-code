/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Constants, descriptors, and functions for the fully connected layer.
*/

import Accelerate

extension TrainingSample {
    
    // MARK: Input, Output, and Parameter Descriptors
    
    static let fullyConnectedWeights: BNNSNDArrayDescriptor = {
        guard let desc = BNNSNDArrayDescriptor.allocate(
            randomUniformUsing: randomGenerator,
            range: Float(-0.5)...Float(0.5),
            shape: .matrixRowMajor(poolingOutputSize,
                                   fullyConnectedOutputWidth)) else {
            fatalError("Unable to create `fullyConnectedWeightsArray`.")
        }
        return desc
    }()
    
    static let fullyConnectedOutputWidth = 10
    static let fullyConnectedWeightSize = fullyConnectedOutputWidth * poolingOutputSize
    
    static let fullyConnectedOutput = BNNSNDArrayDescriptor.allocateUninitialized(
        scalarType: Float.self,
        shape: .vector(fullyConnectedOutputWidth),
        batchSize: batchSize)
    
    // MARK: Layer Creation
    
    static var fullyConnectedLayer: BNNS.FullyConnectedLayer = {
        
        let desc = BNNSNDArrayDescriptor(dataType: .float,
                                         shape: .vector(poolingOutputSize))
        
        guard let fullyConnectedLayer = BNNS.FullyConnectedLayer(
                input: desc,
                output: fullyConnectedOutput,
                weights: fullyConnectedWeights,
                bias: nil,
                activation: .identity,
                filterParameters: filterParameters) else {
            fatalError("Unable to create `fullyConnectedLayer`.")
        }
        
        return fullyConnectedLayer
    }()
    
    // MARK: Backward Apply Function
    
    // The `backwardFully` function backward-applies the fully connected layer,
    // and generates the gradient for weights.
    static func backwardFully() {
        do {
            try fullyConnectedLayer.applyBackward(
                batchSize: batchSize,
                input: poolingOutput,
                output: fullyConnectedOutput,
                outputGradient: lossInputGradient,
                generatingInputGradient: fullyConnectedInputGradient,
                generatingWeightsGradient: fullyConnectedWeightGradient)
        } catch {
            fatalError("`backwardFully()` failed.")
        }
    }
    
    // MARK: Gradient Descriptors
    
    static let fullyConnectedInputGradient = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: .vector(poolingOutputSize),
        batchSize: batchSize)
    
    static let fullyConnectedWeightGradient = BNNSNDArrayDescriptor.allocateUninitialized(
        scalarType: Float.self,
        shape: fullyConnectedWeights.shape)
    
    // MARK: Optimizer Accumulator Descriptors
    
    static let fullyConnectedWeightAccumulator1 = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: fullyConnectedWeights.shape)
    static let fullyConnectedWeightAccumulator2 = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: fullyConnectedWeights.shape)
}
