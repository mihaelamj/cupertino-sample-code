/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience graph wrapper to run training and inference
*/

#ifndef MNISTClassifierGraph_h
#define MNISTClassifierGraph_h

#import "MNISTDataSet.h"
#import "DataSources.h"

@interface MNISTClassifierGraph : NSObject {
@public
    // Keep the MTLDevice and MTLCommandQueue objects around for ease of use.
    id <MTLDevice> device;

    ConvDataSource *conv1Wts, *conv2Wts, *fc1Wts, *fc2Wts;
    MPSNNGraph *trainingGraph, *inferenceGraph;
}
-(nonnull instancetype) initWithDevice:(nonnull id <MTLDevice>) inputDevice;
-(void) initializeInferenceGraph:(nonnull id <MTLDevice>)inputDevice;
-(nonnull MPSNNFilterNode *) createNodesWithTraining:(BOOL) isTraining;
-(MPSImageBatch * __nullable) encodeInferenceBatchToCommandBuffer:(nonnull id <MTLCommandBuffer>) commandBuffer
                                                     sourceImages:(MPSImageBatch * __nonnull) sourceImage;

-(MPSImageBatch * __nullable) encodeTrainingBatchToCommandBuffer:(nonnull id <MTLCommandBuffer>) commandBuffer
                                                    sourceImages:(MPSImageBatch * __nonnull) sourceImage
                                                      lossStates:(MPSCNNLossLabelsBatch * __nonnull) lossStateBatch;

@end


#endif /* MNISTClassifierGraph_h */

