/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main driver file.
*/

#import "Helpers.h"
#import "DataSources.h"
#import "MNISTDataSet.h"
#import "MNISTClassifierGraph.h"


float gLearningRate = 1e-3f;

id<MTLDevice> _Nonnull gDevice;
id<MTLCommandQueue> _Nonnull gCommandQueue;


#pragma mark - definitions

MNISTDataSet *dataset;
MNISTClassifierGraph *classifierGraph;
dispatch_semaphore_t doubleBufferingSemaphore;


#pragma mark - iterations
id <MTLCommandBuffer> runTrainingIterationBatch(){
    @autoreleasepool{
        // Double buffering semaphore to correcly double buffer iterations.
        dispatch_semaphore_wait(doubleBufferingSemaphore, DISPATCH_TIME_FOREVER);

        MPSCNNLossLabelsBatch *lossStateBatch = nil;

        // Sample BATCH_SIZE images from MNIST training dataset.
        MPSImageBatch *randomTrainBatch = [dataset getRandomTrainingBatchWithDevice:gDevice
                                                                          batchSize:BATCH_SIZE
                                                                     lossStateBatch:&lossStateBatch];

        // Make an MPSCommandBuffer, when passed to the encode of MPSNNGraph, commitAndContinue will be automatically used.
        MPSCommandBuffer *commandBuffer = [MPSCommandBuffer commandBufferFromCommandQueue:gCommandQueue];

        // Encode training iteration on commandBuffer.
        MPSImageBatch *returnBatch = [classifierGraph encodeTrainingBatchToCommandBuffer: commandBuffer
                                                                            sourceImages: randomTrainBatch
                                                                              lossStates: lossStateBatch];

        // Get the loss images from the state object.
        MPSImageBatch *outputBatch = @[];
        for(NSUInteger i = 0; i < BATCH_SIZE; i++){
            outputBatch = [outputBatch arrayByAddingObject: [lossStateBatch[i] lossImage]];
        }
        static int iteration = 1;
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuf) {
            // Release double buffering semaphore for the next training iteration to be encoded.
            dispatch_semaphore_signal(doubleBufferingSemaphore);

            // Reduce loss across batch
            float trainingLoss = lossReduceSumAcrossBatch(outputBatch);
            printf("Iteration %d, Training loss = %f\n", iteration, trainingLoss);
            iteration++;

            // Always check if commandBuffer finished with an error.
            NSError *err = cmdBuf.error;
            if(err){
                NSLog(@"%@", err);
            }
        }];

        // Transfer data from GPU to CPU (will be a no-op on embedded GPUs).
        MPSImageBatchSynchronize(returnBatch, commandBuffer);
        MPSImageBatchSynchronize(outputBatch, commandBuffer);

        // Commit the command buffer
        [commandBuffer commit];

        return commandBuffer;
    }
}

#pragma mark - dataset evaluation

void evaluateTestSet(NSUInteger iterations){
    @autoreleasepool{
        // Reset accuracy counters, begin a fresh test set evaluation.
        gDone = 0;
        gCorrect = 0;

        // Rpdate inference graph weights with the trained weights.
        [classifierGraph->inferenceGraph reloadFromDataSources];

        MPSImageDescriptor *inputDesc = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                                                                       width:MNIST_IMAGE_SIZE
                                                                                      height:MNIST_IMAGE_SIZE
                                                                             featureChannels:1
                                                                              numberOfImages:1
                                                                                       usage:MTLTextureUsageShaderRead];
        // Keeping track of latestCommanBuffer.
        MPSCommandBuffer *lastcommandBuffer = nil;

        // Encoding each image.
        for(NSUInteger currImageIdx = 0; currImageIdx < dataset->totalNumberOfTestImages; currImageIdx+=BATCH_SIZE) @autoreleasepool{

            // Fouble buffering semaphore to correctly double buffer iterations.
            dispatch_semaphore_wait(doubleBufferingSemaphore, DISPATCH_TIME_FOREVER);

            // Create an input MPSImageBatch.
            MPSImageBatch *inputBatch = @[];
            for(NSUInteger i = 0; i < BATCH_SIZE; i++){
                MPSImage *inputImage = [[MPSImage alloc] initWithDevice:gDevice
                                                        imageDescriptor:inputDesc];
                inputBatch = [inputBatch arrayByAddingObject: inputImage];
            }

            // Make an MPSCommandBuffer, when passed to the encode of MPSNNGraph, commitAndContinue will be automatically used.
            MPSCommandBuffer *commandBuffer = [MPSCommandBuffer commandBufferFromCommandQueue:gCommandQueue];

            // write the image data to from MNIST Testing dataset to the MPSImageBatch.
            [inputBatch enumerateObjectsUsingBlock:^(MPSImage * _Nonnull inputImage, NSUInteger idx, BOOL * _Nonnull stop) {
                uint8_t *start = ADVANCE_PTR(dataset->testImagePointer, MNIST_IMAGE_METADATA_PREFIX_SIZE + (MNIST_IMAGE_SIZE * MNIST_IMAGE_SIZE * (currImageIdx + idx)));
                [inputImage writeBytes:start
                            dataLayout:(MPSDataLayoutHeightxWidthxFeatureChannels)
                            imageIndex:0];
            }];

            // Encode inference network
            MPSImageBatch *outputBatch = [classifierGraph encodeInferenceBatchToCommandBuffer:commandBuffer
                                                                                 sourceImages:inputBatch];
            // Transfer data from GPU to CPU (will be a no-op on embedded GPUs)
            MPSImageBatchSynchronize(outputBatch, commandBuffer);

            [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
                // Release double buffering semaphore for the next training iteration to be encoded.
                dispatch_semaphore_signal(doubleBufferingSemaphore);
                // Check the output of inference network to calculate accuracy.
                [outputBatch enumerateObjectsUsingBlock:^(MPSImage * _Nonnull outputImage, NSUInteger idx, BOOL * _Nonnull stop) {
                    uint8_t *labelStart = ADVANCE_PTR(dataset->testLabelPointer, MNIST_LABELS_METADATA_PREFIX_SIZE + currImageIdx + idx);
                    checkDigitLabel<IMAGE_T>(outputImage, labelStart);
                }];

            }];

            // Commit the command buffer
            [commandBuffer commit];
            lastcommandBuffer = commandBuffer;
        }

        // Wait for the last batch to be processed.
        [lastcommandBuffer waitUntilCompleted];
        NSLog(@"Test Set Accuracy = %f %%", (float)(gCorrect / ((float)(dataset->totalNumberOfTestImages) / 100.f)));
    }
}

#pragma mark - main driver method

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Get the metal device and commandQueue to be used.
        gDevice = MTLCreateSystemDefaultDevice();
        gCommandQueue = [gDevice newCommandQueue];

        // Use double buffering to keep the gpu completely busy.
        doubleBufferingSemaphore = dispatch_semaphore_create(2);

        // Make the MNISTDataset.
        dataset = [[MNISTDataSet alloc] init];

        // Create the classifier network
        classifierGraph = [[MNISTClassifierGraph alloc] initWithDevice:gDevice];

        id <MTLCommandBuffer> latestCommandBuffer = nil;
        // Begin training for TRAINING_ITARATIONS
        for(NSUInteger i = 0; i < TRAINING_ITARATIONS; i++) @autoreleasepool{
            // Test set evaluation after every TEST_SET_EVAL_INTERVAL iterations.
            if((i % TEST_SET_EVAL_INTERVAL) == 0){ // epoch
                if(latestCommandBuffer){
                    // wait for training to finish before evaluation test set/
                    [latestCommandBuffer waitUntilCompleted];
                }
                evaluateTestSet(i);
            }
            // Run the training iteration.
            latestCommandBuffer = runTrainingIterationBatch();
        }
        // Final Test set evaluation after training.
        evaluateTestSet(TRAINING_ITARATIONS);
    } // @autoreleasepool
    NSLog(@"Done");

    return 0;
}
