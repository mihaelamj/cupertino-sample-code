/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience wrapper to work with the dataset
*/

#ifndef MNISTDataSet_h
#define MNISTDataSet_h

#import "DataSources.h"

#define MNIST_IMAGE_SIZE 28
#define MNIST_IMAGE_METADATA_PREFIX_SIZE 16
#define MNIST_LABELS_METADATA_PREFIX_SIZE 8

/*!
 *  @class      MNISTDataSet
 *
 */

@interface MNISTDataSet : NSObject{
@public

    NSUInteger totalNumberOfTrainImages;
    uint8_t *trainImagePointer, *trainLabelPointer;
    size_t sizeTrainLabels, sizeTrainImages;
    NSData *dataTrainImage;
    NSData *dataTrainLabel;

    NSUInteger totalNumberOfTestImages;
    uint8_t *testImagePointer, *testLabelPointer;
    size_t sizeTestLabels, sizeTestImages;
    NSData *dataTestImage;
    NSData *dataTestLabel;


    unsigned seed;
}

-(nullable instancetype) init;

-(nullable MPSImageBatch *) getRandomTrainingBatchWithDevice: (id <MTLDevice> _Nonnull) device
                                                   batchSize: (NSUInteger) batchSize
                                              lossStateBatch: (MPSCNNLossLabelsBatch * __nonnull * __nullable)lossStateBatch;


@end    /* MNISTDataSet */

#endif /* MNISTDataSet_h */
