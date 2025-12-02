/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Datasource for the layers, weight update is defined here
*/

#import "Controls.h"
#import "DataSources.h"
#import <random>

@implementation ConvDataSource

-(nonnull instancetype) initWithKernelWidth:(NSUInteger)kernelWidth
                               kernelHeight:(NSUInteger)kernelHeight
                       inputFeatureChannels:(NSUInteger)inputFeatureChannels
                      outputFeatureChannels:(NSUInteger)outputFeatureChannels
                                     stride:(NSUInteger)stride
                                      label:(NSString * __nonnull)label
{
    self = [super init];
    if( nil == self )
        return nil;

    _label = label;
    _outputFeatureChannels = outputFeatureChannels;
    _inputFeatureChannels = inputFeatureChannels;
    _kernelWidth = kernelWidth;
    _kernelHeight = kernelHeight;

    _convDesc = [MPSCNNConvolutionDescriptor cnnConvolutionDescriptorWithKernelWidth:kernelWidth
                                                                        kernelHeight:kernelHeight
                                                                inputFeatureChannels:inputFeatureChannels
                                                               outputFeatureChannels:outputFeatureChannels];

    _convDesc.strideInPixelsX = stride;
    _convDesc.strideInPixelsY = stride;
    _convDesc.fusedNeuronDescriptor = [MPSNNNeuronDescriptor cnnNeuronDescriptorWithType:(MPSCNNNeuronTypeNone)];

    // Calculating the size of weights and biases.
    _sizeBiases = _outputFeatureChannels * sizeof(float);
    NSUInteger lenWeights = _inputFeatureChannels * _kernelHeight * _kernelWidth * _outputFeatureChannels;
    _sizeWeights = lenWeights * sizeof(float);



    // Setting standard adam update parameters.
    _learning_rate = gLearningRate;
    _beta1 = 0.9f;
    _beta2 = 0.999f;
    _epsilon = 1e-08f;
    _t = 0.f;

    MPSNNOptimizerDescriptor *desc = [MPSNNOptimizerDescriptor optimizerDescriptorWithLearningRate:_learning_rate
                                                                                   gradientRescale:1.0f
                                                                                regularizationType:MPSNNRegularizationTypeNone
                                                                               regularizationScale:1.0f];

    _updater = [[MPSNNOptimizerAdam alloc] initWithDevice:gDevice
                                                    beta1:_beta1
                                                    beta2:_beta2
                                                  epsilon:_epsilon
                                                 timeStep:0
                                      optimizerDescriptor:desc];

    _vDescWeights = [MPSVectorDescriptor vectorDescriptorWithLength:lenWeights
                                                           dataType:(MPSDataTypeFloat32)];

    _weightMomentumVector = [[MPSVector alloc] initWithDevice:gDevice
                                                   descriptor:_vDescWeights];

    _weightVelocityVector = [[MPSVector alloc] initWithDevice:gDevice
                                                   descriptor:_vDescWeights];

    _weightVector = [[MPSVector alloc] initWithDevice:gDevice
                                           descriptor:_vDescWeights];

    _vDescBiases = [MPSVectorDescriptor vectorDescriptorWithLength:_outputFeatureChannels
                                                          dataType:(MPSDataTypeFloat32)];

    _biasMomentumVector = [[MPSVector alloc] initWithDevice:gDevice
                                                 descriptor:_vDescBiases];

    _biasVelocityVector = [[MPSVector alloc] initWithDevice:gDevice
                                                 descriptor:_vDescBiases];

    _biasVector = [[MPSVector alloc] initWithDevice:gDevice
                                         descriptor:_vDescBiases];





    _convWtsAndBias = [[MPSCNNConvolutionWeightsAndBiasesState alloc] initWithWeights:_weightVector.data
                                                                               biases:_biasVector.data];

    // Initializing weights, biases and their corresponding weights and biases.
    _weightPointer = (float *)_weightVector.data.contents;
    _weightMomentumPointer = (float *)_weightMomentumVector.data.contents;
    _weightVelocityPointer = (float *)_weightVelocityVector.data.contents;
    float zero = 0.f;
    memset_pattern4( (void *)_weightMomentumPointer, (char *)&zero, _sizeWeights);
    memset_pattern4( (void *)_weightVelocityPointer, (char *)&zero, _sizeWeights);

    _biasPointer = (float *)_biasVector.data.contents;
    _biasMomentumPointer = (float *)_biasMomentumVector.data.contents;
    _biasVelocityPointer = (float *)_biasVelocityVector.data.contents;
    memset_pattern4( (void *)_biasMomentumPointer, (char *)&zero, _sizeBiases);
    memset_pattern4( (void *)_biasVelocityPointer, (char *)&zero, _sizeBiases);
    float biasInit = 0.1f;
    memset_pattern4( (void *)_biasPointer, (char *)&biasInit, _sizeBiases);


    // Setting weights to random values.
    MPSMatrixRandomDistributionDescriptor *randomDesc = [MPSMatrixRandomDistributionDescriptor uniformDistributionDescriptorWithMinimum:-0.2f
                                                                                                                                maximum:0.2f];
    MPSMatrixRandomMTGP32 *randomKernel = [[MPSMatrixRandomMTGP32 alloc] initWithDevice:gDevice
                                                                    destinationDataType:MPSDataTypeFloat32
                                                                                   seed:_seed
                                                                 distributionDescriptor:randomDesc];

    MPSCommandBuffer *commandBuffer = [MPSCommandBuffer commandBufferFromCommandQueue:gCommandQueue];
    [randomKernel encodeToCommandBuffer:commandBuffer
                      destinationVector:_weightVector];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];


    [_weightMomentumVector.data didModifyRange:NSMakeRange(0, _sizeWeights)];
    [_weightVelocityVector.data didModifyRange:NSMakeRange(0, _sizeWeights)];
    [_biasVector.data didModifyRange:NSMakeRange(0, _sizeBiases)];
    [_biasMomentumVector.data didModifyRange:NSMakeRange(0, _sizeBiases)];
    [_biasVelocityVector.data didModifyRange:NSMakeRange(0, _sizeBiases)];

    return self;
}

-(MPSDataType)  dataType{return  MPSDataTypeFloat32;}
-(MPSCNNConvolutionDescriptor * __nonnull) descriptor{return _convDesc;}
-(void * __nonnull) weights{return _weightPointer;}
-(float * __nullable) biasTerms{return _biasPointer;};

-(BOOL) load{
    [self checkpointWithCommandQueue:gCommandQueue];
    return YES;
}

-(void) purge{};




-(MPSCNNConvolutionWeightsAndBiasesState* __nullable) updateWithCommandBuffer: (__nonnull id<MTLCommandBuffer>) commandBuffer
                                                                gradientState: (MPSCNNConvolutionGradientState* __nonnull) gradientState
                                                                  sourceState: (MPSCNNConvolutionWeightsAndBiasesState* __nonnull) sourceState{

    _t++;
    _updater.learningRate = gLearningRate;
    [_updater encodeToCommandBuffer:commandBuffer
           convolutionGradientState:gradientState
             convolutionSourceState:sourceState
               inputMomentumVectors:@[_weightMomentumVector, _biasMomentumVector]
               inputVelocityVectors:@[_weightVelocityVector, _biasVelocityVector]
                        resultState:_convWtsAndBias];

    assert(_t == _updater.timeStep);

    return _convWtsAndBias;
}



-(void) checkpointWithCommandQueue:(nonnull id<MTLCommandQueue>) commandQueue{
    @autoreleasepool{
        MPSCommandBuffer *commandBuffer = [MPSCommandBuffer commandBufferFromCommandQueue:gCommandQueue];
        [_convWtsAndBias synchronizeOnCommandBuffer:commandBuffer];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
}

- (NSString * _Nullable)label {
    return _label;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    /* unimplemented */
    return self;
}

@end    /* ConvDataSource */

