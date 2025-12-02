/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Constants, descriptors, and functions for the fused convolution-batch normalization layer.
*/

import Accelerate

extension TrainingSample {
    
    // MARK: Input, Output, and Parameter Descriptors
    
    static let convolutionOutputImageChannels = 32
    
    static let convolutionInputImageWidth = 20
    static let convolutionInputImageHeight = 20
    static let convolutionInputImageChannels = 1
    static let convolutionPadding = 1
    
    static let convolutionOutputImageWidth = 20
    static let convolutionOutputImageHeight = 20
    
    static let convolutionWeights: BNNSNDArrayDescriptor = {
        let convolutionKernelSize = 3
        
        let convolutionWeightsShape = BNNS.Shape.convolutionWeightsOIHW(
            convolutionKernelSize,
            convolutionKernelSize,
            convolutionInputImageChannels,
            convolutionOutputImageChannels)
        
        guard let desc = BNNSNDArrayDescriptor.allocate(
            randomUniformUsing: randomGenerator,
            range: Float(-0.5)...Float(0.5),
            shape: convolutionWeightsShape) else {
            fatalError("Unable to create `convolutionWeightsArray`.")
        }
        return desc
    }()
    
    static let convolutionBias = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: .vector(convolutionOutputImageChannels))
    
    static let featureMaps = convolutionOutputImageChannels
    
    static let batchNormBeta = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: .vector(featureMaps),
        batchSize: batchSize)
    
    static let batchNormGamma = BNNSNDArrayDescriptor.allocate(
        repeating: Float(1),
        shape: .vector(featureMaps),
        batchSize: batchSize)
    
    static let batchNormMovingVariance = BNNSNDArrayDescriptor.allocate(
        repeating: Float(1),
        shape: .vector(featureMaps),
        batchSize: batchSize)
    
    static let batchNormMovingMean = BNNSNDArrayDescriptor.allocate(
        repeating: Float(1),
        shape: .vector(featureMaps),
        batchSize: batchSize)
    
    static let batchNormOutput = BNNSNDArrayDescriptor.allocateUninitialized(
        scalarType: Float.self,
        shape: .imageCHW(convolutionOutputImageWidth,
                         convolutionOutputImageHeight,
                         convolutionOutputImageChannels),
        batchSize: batchSize)
    
    // MARK: Layer Creation
    
    static let fusedConvBatchNormLayer: BNNS.FusedParametersLayer = {
        
        let convolutionParameters = BNNS.FusedConvolutionParameters(
            type: .standard,
            weights: convolutionWeights,
            bias: convolutionBias,
            stride: (1, 1),
            dilationStride: (1, 1),
            groupSize: 1,
            padding: .symmetric(x: convolutionPadding,
                                y: convolutionPadding))
        
        let normalizationParameters = BNNS.FusedNormalizationParameters(
            type: .batch(movingMean: batchNormMovingMean,
                         movingVariance: batchNormMovingVariance),
            beta: batchNormBeta,
            gamma: batchNormGamma,
            momentum: 0.9,
            epsilon: 1e-07,
            activation: .rectifiedLinear)
        
        guard let layer = BNNS.FusedParametersLayer(
            input: input,
            output: batchNormOutput,
            fusedLayerParameters: [convolutionParameters, normalizationParameters],
            filterParameters: filterParameters) else {
            fatalError("unable to create fusedConvBatchnormLayer")
        }
        
        return layer
    }()

    // MARK: Backward Apply Function
    
    // The `backwardFused` function backward-applies the fused layer and generates
    // gradients for convolution weights and bias, and batch normalization beta
    // and gamma.
    static func backwardFused() {
        do {
            let gradientParameters = [convolutionWeightGradient,
                                      convolutionBiasGradient,
                                      batchNormBetaGradient,
                                      batchNormGammaGradient]
            
            try fusedConvBatchNormLayer.applyBackward(
                batchSize: batchSize,
                input: input,
                output: batchNormOutput,
                outputGradient: poolingInputGradientArray,
                generatingInputGradient: convolutionInputGradient,
                generatingParameterGradients: gradientParameters)
        } catch {
            fatalError("`backwardFused()` failed.")
        }
    }
    
    // MARK: Gradient Descriptors
    
    static let convolutionInputGradient = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: input.shape,
        batchSize: batchSize)
    
    static let convolutionWeightGradient = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: convolutionWeights.shape)
    
    static let convolutionBiasGradient = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: convolutionBias.shape)
    
    static let batchNormBetaGradient = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: .vector(featureMaps))
    
    static let batchNormGammaGradient = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: .vector(featureMaps))
    
    // MARK: Optimizer Accumulator Descriptors
    
    static let convolutionWeightAccumulator1 = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: convolutionWeights.shape)
    static let convolutionWeightAccumulator2 = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: convolutionWeights.shape)
    static let convolutionBiasAccumulator1 = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: convolutionBias.shape)
    static let convolutionBiasAccumulator2 = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: convolutionBias.shape)
    
    static let batchNormBetaAccumulator1 = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: batchNormBeta.shape)
    static let batchNormBetaAccumulator2 = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: batchNormBeta.shape)
    static let batchNormGammaAccumulator1 = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: batchNormGamma.shape)
    static let batchNormGammaAccumulator2 = BNNSNDArrayDescriptor.allocate(
        repeating: Float(0),
        shape: batchNormGamma.shape)
}
