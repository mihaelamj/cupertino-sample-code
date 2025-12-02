/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Some contol parameters shared across the classifier.
*/

#ifndef Controls_h
#define Controls_h

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#define TRAINING_ITARATIONS 300
#define TEST_SET_EVAL_INTERVAL 100

#define IMAGE_T __fp16
static MPSImageFeatureChannelFormat fcFormat = MPSImageFeatureChannelFormatFloat16;

#define BATCH_SIZE 40


#endif /* Controls_h */
