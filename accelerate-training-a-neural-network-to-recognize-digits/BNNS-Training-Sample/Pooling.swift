/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Constants, descriptors, and functions for the pooling layer .
*/

import Accelerate

extension TrainingSample {
    
    // MARK: Input, Output, and Parameter Descriptors
    
    static let poolingOutputImageWidth = convolutionOutputImageWidth / 2
    static let poolingOutputImageHeight = convolutionOutputImageWidth / 2
    static let poolingOutputImageChannels = convolutionOutputImageChannels
    static let poolingOutputSize = poolingOutputImageWidth * poolingOutputImageHeight * poolingOutputImageChannels
    
    static let poolingOutput = BNNSNDArrayDescriptor.allocateUninitialized(
        scalarType: Float.self,
        shape: .imageCHW(poolingOutputImageWidth,
                         poolingOutputImageHeight,
                         poolingOutputImageChannels),
        batchSize: batchSize)
    
    // MARK: Layer Creation
    
    static var poolingLayer: BNNS.PoolingLayer = {
        guard let poolingLayer = BNNS.PoolingLayer(
            type: .max(xDilationStride: 1, yDilationStride: 1),
            input: batchNormOutput,
            output: poolingOutput,
            bias: nil,
            activation: .identity,
            kernelSize: (2, 2),
            stride: (2, 2),
            padding: .zero,
            filterParameters: filterParameters) else {
            fatalError("Unable to create `poolingLayer`.")
        }
        
        return poolingLayer
    }()
    
    // MARK: Backward Apply Function
    
    // The `backwardPooling` backward-applies the pooling layer.
    static func backwardPooling() {
        do {
            try poolingLayer.applyBackward(
                batchSize: batchSize,
                input: batchNormOutput,
                output: poolingOutput,
                outputGradient: fullyConnectedInputGradient,
                generatingInputGradient: poolingInputGradientArray)
        } catch {
            fatalError("`backwardPooling()` failed.")
        }
    }
    
    // MARK: Gradient Descriptors
    
    static let poolingInputGradientArray = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: batchNormOutput.shape,
        batchSize: batchSize)
}
