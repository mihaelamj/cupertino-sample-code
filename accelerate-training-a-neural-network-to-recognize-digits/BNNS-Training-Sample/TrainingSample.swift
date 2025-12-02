/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that runs a digit recognizer.
*/

import Accelerate

struct TrainingSample {
    
    // Specify `useClientPointer` to instruct the layers to keep the provided
    // pointers at creation time, and to work directly from that data rather than
    // use internal copies of the data.
    static var filterParameters = BNNSFilterParameters(
        flags: BNNSFlags.useClientPointer.rawValue,
        n_threads: 1,
        alloc_memory: nil,
        free_memory: nil)
    
    static let batchSize = 32
    
    // The one-hot labels array contains a `1` at the index of the digit.
    // For example, `[0, 0, 0, 1, 0, 0, 0, 0, 0, 0]` represents `3`.
    static let oneHotLabelsWidth = fullyConnectedOutputWidth
    
    static var oneHotLabels = BNNSNDArrayDescriptor.allocateUninitialized(
        scalarType: Float.self,
        shape: .vector(oneHotLabelsWidth),
        batchSize: batchSize)
    
    // The `input` array descriptor contains the images of the digits.
    static let input = BNNSNDArrayDescriptor.allocateUninitialized(
        scalarType: Float.self,
        shape: .imageCHW(convolutionInputImageWidth,
                         convolutionInputImageHeight,
                         convolutionInputImageChannels),
        batchSize: batchSize)

    static let randomGenerator: BNNS.RandomGenerator = {
        guard let rng = BNNS.RandomGenerator(method: .aesCtr) else {
            fatalError("Unable to create `RandomGenerator`.")
        }
        return rng
    }()

    static func testExample() {
        runTrainingExample()
        
        let score = test()
        
        freeArrayDescriptors()
        
        print("Training sample test accuracy: \(score)")
    }
    
    static func runTrainingExample() {
        let maximumIterationCount = 1000
        
        // The `recentLosses` array contains the last `recentLossesCount` losses.
        let recentLossesCount = 20
        var recentLosses = [Float]()
        
        // The `averageRecentLossThreshold` constant defines the loss threshold
        // at which to consider the training phase complete.
        let averageRecentLossThreshold = Float(0.125)
        
        for epoch in 0 ..< maximumIterationCount {
            if epoch == 500 {
                adam.learningRate /= 10
            }
            
            generateInputAndLabels()
            forwardPass()
            computeLoss()
            
            guard let loss = lossOutput.makeArray(of: Float.self,
                                                  batchSize: 1)?.first else {
                print("Unable to calculate loss.")
                return
            }
            
            if recentLosses.isEmpty {
                recentLosses = [Float](repeating: loss,
                                       count: recentLossesCount)
            }
            
            recentLosses[epoch % recentLossesCount] = loss
            let averageRecentLoss = vDSP.mean(recentLosses)
            
            if epoch % 10 == 0 {
                print("Epoch \(epoch): \(loss) : \(averageRecentLoss)")
            }
            
            if averageRecentLoss < averageRecentLossThreshold {
                print("Recent average loss: \(averageRecentLoss), breaking at epoch \(epoch).")
                break
            }
            
            backwardPass()
        }
    }
    
    // The `forwardPass` function performs a forward pass by calling `apply` on
    // the fused, pooling, and fully connected layers.
    static func forwardPass() {
        do {
            try fusedConvBatchNormLayer.apply(batchSize: batchSize,
                                              input: input,
                                              output: batchNormOutput,
                                              for: .training)
            
            try poolingLayer.apply(batchSize: batchSize,
                                   input: batchNormOutput,
                                   output: poolingOutput)
            
            try fullyConnectedLayer.apply(batchSize: batchSize,
                                          input: poolingOutput,
                                          output: fullyConnectedOutput)
        } catch {
            fatalError("Forward pass failed.")
        }
    }
    
    // The `backwardPass` function performs a backward pass by calling
    // `applyBackward` on the fully connected layer, pooling layer, and fused layer.
    // After completing the backward pass, the function applies an optimizer step
    // to the fully connected and fused parameters.
    static func backwardPass() {
        backwardFully()
        backwardPooling()
        backwardFused()
        
        optimizerStep()
    }
    
    // MARK: Backward pass and optimization step
    
    static var adam = BNNS.AdamOptimizer(learningRate: 0.01,
                                         timeStep: 1,
                                         gradientScale: 1,
                                         regularizationScale: 0.01,
                                         gradientClipping: .byValue(bounds: -0.5 ... 0.5),
                                         regularizationFunction: BNNSOptimizerRegularizationL2)
    
    // The `optimizerStep` function applies an optimizer step to the fully
    // connected weights, the convolution weights and bias, and the batch
    // normalization beta and gamma.
    static func optimizerStep() {
        do {
            try adam.step(
                parameters: [fullyConnectedWeights,
                             convolutionWeights, convolutionBias,
                             batchNormBeta, batchNormGamma],
                gradients: [fullyConnectedWeightGradient,
                            convolutionWeightGradient, convolutionBiasGradient,
                            batchNormBetaGradient, batchNormGammaGradient],
                accumulators: [fullyConnectedWeightAccumulator1,
                               convolutionWeightAccumulator1, convolutionBiasAccumulator1,
                               batchNormBetaAccumulator1, batchNormGammaAccumulator1,
                               fullyConnectedWeightAccumulator2,
                               convolutionWeightAccumulator2, convolutionBiasAccumulator2,
                               batchNormBetaAccumulator2, batchNormGammaAccumulator2],
                filterParameters: filterParameters)
        } catch {
            fatalError("`optimizerFused()` failed.")
        }
        adam.timeStep += 1
    }
}

