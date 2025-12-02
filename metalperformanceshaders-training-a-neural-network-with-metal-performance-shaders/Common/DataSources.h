/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Datasource for the layers, weight update is defined here.
*/

#ifndef DataSources_h
#define DataSources_h

#import "Controls.h"

#ifndef ADVANCE_PTR
#   define  ADVANCE_PTR(_a, _size)                 (__typeof__(_a))((uintptr_t) (_a) + (size_t)(_size))
#endif

extern float gLearningRate;

extern id<MTLDevice> _Nonnull gDevice;
extern id<MTLCommandQueue> _Nonnull gCommandQueue;


static MPSNNDefaultPadding * _Nonnull sameConvPadding = [MPSNNDefaultPadding paddingWithMethod: MPSNNPaddingMethodAddRemainderToTopLeft | MPSNNPaddingMethodAlignCentered | MPSNNPaddingMethodSizeSame];
static MPSNNDefaultPadding * _Nonnull validConvPadding = [MPSNNDefaultPadding paddingWithMethod: MPSNNPaddingMethodAlignCentered | MPSNNPaddingMethodAddRemainderToTopLeft | MPSNNPaddingMethodSizeValidOnly];

static MPSNNDefaultPadding * _Nonnull samePoolingPadding = [MPSNNDefaultPadding paddingForTensorflowAveragePooling];
static MPSNNDefaultPadding * _Nonnull validPoolingPadding = [MPSNNDefaultPadding paddingForTensorflowAveragePoolingValidOnly];

/*!
 *  @class      ConvDataSource
 *  @dependency This depends on Metal.framework
 *
 */
@interface ConvDataSource : NSObject<MPSCNNConvolutionDataSource>{
@private
    NSUInteger _outputFeatureChannels;
    NSUInteger _inputFeatureChannels;
    NSUInteger _kernelHeight;
    NSUInteger _kernelWidth;
    MPSCNNConvolutionDescriptor *_convDesc;
    NSString *_label;
    float *_biasPointer, *_weightPointer, *_biasMomentumPointer, *_biasVelocityPointer, *_weightVelocityPointer, *_weightMomentumPointer;
    size_t _sizeBiases, _sizeWeights;
    unsigned _seed;


    float _learning_rate;
    float _beta1;
    float _beta2;
    float _epsilon;
    float _t;

    MPSVector *_weightMomentumVector, *_biasMomentumVector, *_weightVelocityVector, *_biasVelocityVector, *_weightVector, *_biasVector;

    MPSNNOptimizerAdam *_updater;

    MPSVectorDescriptor *_vDescWeights;
    MPSVectorDescriptor *_vDescBiases;

@public
    MPSCNNConvolutionWeightsAndBiasesState* _convWtsAndBias;
}

-(nonnull instancetype) initWithKernelWidth:(NSUInteger)kernelWidth
                               kernelHeight:(NSUInteger)kernelHeight
                       inputFeatureChannels:(NSUInteger)inputFeatureChannels
                      outputFeatureChannels:(NSUInteger)outputFeatureChannels
                                     stride:(NSUInteger)stride
                                      label:(NSString * __nonnull)label;

-(MPSDataType)  dataType;
-(MPSCNNConvolutionDescriptor * __nonnull) descriptor;
-(void * __nonnull) weights;
-(float * __nullable) biasTerms;
-(BOOL) load;
-(void) purge;

-(MPSCNNConvolutionWeightsAndBiasesState* __nullable) updateWithCommandBuffer: (__nonnull id<MTLCommandBuffer>) commandBuffer
                                                                gradientState: (MPSCNNConvolutionGradientState* __nonnull) gradientState
                                                                  sourceState: (MPSCNNConvolutionWeightsAndBiasesState* __nonnull) sourceState;
-(void) checkpointWithCommandQueue:(nonnull id<MTLCommandQueue>) commandQueue;
@end    /* ConvDataSource */

#endif /* DataSources_h */
