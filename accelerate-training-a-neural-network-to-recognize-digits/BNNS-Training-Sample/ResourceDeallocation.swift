/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The resource deallocation extension.
*/

import Accelerate

extension TrainingSample {
    // The `freeArrayDescriptors` function deallocates the allocated memory for
    // the array descriptors.
    static func freeArrayDescriptors() {
        oneHotLabels.deallocate()
        input.deallocate()
        convolutionWeights.deallocate()
        convolutionBias.deallocate()
        batchNormOutput.deallocate()
        batchNormBeta.deallocate()
        batchNormGamma.deallocate()
        batchNormMovingVariance.deallocate()
        batchNormMovingMean.deallocate()
        poolingOutput.deallocate()
        fullyConnectedWeights.deallocate()
        fullyConnectedOutput.deallocate()
        lossOutput.deallocate()
        lossInputGradient.deallocate()
        fullyConnectedInputGradient.deallocate()
        fullyConnectedWeightGradient.deallocate()
        fullyConnectedWeightAccumulator1.deallocate()
        fullyConnectedWeightAccumulator2.deallocate()
        convolutionInputGradient.deallocate()
        convolutionWeightGradient.deallocate()
        convolutionBiasGradient.deallocate()
        batchNormBetaGradient.deallocate()
        batchNormGammaGradient.deallocate()
        convolutionWeightAccumulator1.deallocate()
        convolutionWeightAccumulator2.deallocate()
        convolutionBiasAccumulator1.deallocate()
        convolutionBiasAccumulator2.deallocate()
        batchNormBetaAccumulator1.deallocate()
        batchNormBetaAccumulator2.deallocate()
        batchNormGammaAccumulator1.deallocate()
        batchNormGammaAccumulator2.deallocate()
        poolingInputGradientArray.deallocate()
    }
}
