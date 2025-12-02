/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Minor helper functions.
*/

#ifndef Helpers_h
#define Helpers_h

#import "MNISTDataSet.h"

extern NSUInteger gDone, gCorrect;

float lossReduceSumAcrossBatch(MPSImageBatch * _Nonnull batch);

template<typename T>
void checkDigitLabel(MPSImage * _Nonnull image, uint8_t* _Nonnull labelStart){

    assert(image.numberOfImages == 1);

    NSUInteger numActualValues = image.height * image.width * image.featureChannels;

    T * vals =  (T *)malloc(sizeof(T) * numActualValues);

    float setVal = -22.f;
    memset_pattern4(vals, &setVal, numActualValues * sizeof(T));

    T max = -100.f;
    int index = -1;

    [image readBytes:vals dataLayout:(MPSDataLayoutFeatureChannelsxHeightxWidth) imageIndex:0];

    for(NSUInteger i = 0; i < (NSUInteger)image.featureChannels; i++){
        for(NSUInteger j = 0; j < image.height; j++){
            for(NSUInteger k = 0; k < image.width; k++){
                T mpsVal = (T) vals[(i * image.height + j) * image.width + k];
                if(mpsVal > max){
                    max = mpsVal;
                    index = (int)((i * image.height + j) * image.width + k);
                }
            }
        }
    }

    if(index == labelStart[0])
        gCorrect++;

    gDone++;
    free(vals);
}

#endif /* Helpers_h */
