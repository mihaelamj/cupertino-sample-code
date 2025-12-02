/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit extension file.
*/

#import "vDSP_audio_unitExtensionAudioUnit.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/AUViewController.h>

#import "vDSP_audio_unitExtensionBufferedAudioBus.hpp"
#import "vDSP_audio_unitExtensionAUProcessHelper.hpp"
#import "vDSP_audio_unitExtensionDSPKernel.hpp"

@interface vDSP_audio_unitExtensionAudioUnit ()

@property (nonatomic, readwrite) AUParameterTree *parameterTree;
@property AUAudioUnitBusArray *inputBusArray;
@property AUAudioUnitBusArray *outputBusArray;
@property (nonatomic, readonly) AUAudioUnitBus *outputBus;
@end


@implementation vDSP_audio_unitExtensionAudioUnit {
    // C++ members need to be instance variables because they would be copied on access if they were properties.
    vDSP_audio_unitExtensionDSPKernel _kernel;
    BufferedInputBus _inputBus;
    std::unique_ptr<AUProcessHelper> _processHelper;
}

@synthesize parameterTree = _parameterTree;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];
    
    if (self == nil) { return nil; }
    
    [self setupAudioBuses];
    
    return self;
}

#pragma mark - AUAudioUnit Setup

- (void)setupAudioBuses {
    // Create the output bus first.
    AVAudioFormat *format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
    _outputBus = [[AUAudioUnitBus alloc] initWithFormat:format error:nil];
    _outputBus.maximumChannelCount = 8;
    
    // Create the input and output busses.
    _inputBus.init(format, 8);
    
    // Create the input bus arrays.
    _inputBusArray  = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
                                                             busType:AUAudioUnitBusTypeInput
                                                              busses: @[_inputBus.bus]];
    // Create the output bus arrays.
    _outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
                                                             busType:AUAudioUnitBusTypeOutput
                                                              busses: @[_outputBus]];
}

- (void)setupParameterTree:(AUParameterTree *)parameterTree {
    _parameterTree = parameterTree;
    
    // Send the parameter default values to the kernel before setting up the parameter callbacks, so that the defaults set in the kernel don't propagate back to the `AUParameters` via `GetParameter`.
    for (AUParameter *param in _parameterTree.allParameters) {
        _kernel.setParameter(param.address, param.value);
    }
    
    [self setupParameterCallbacks];
}

- (void)setupParameterCallbacks {
    // Make a local pointer to the kernel to avoid capturing self.
    
    __block vDSP_audio_unitExtensionDSPKernel *kernel = &_kernel;
    
    // The audio unit calls `implementorValueObserver` when a parameter changes value.
    _parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
        kernel->setParameter(param.address, value);
    };
    
    // The audio unit calls `implementorValueProvider` when the value needs to be refreshed.
    _parameterTree.implementorValueProvider = ^(AUParameter *param) {
        return kernel->getParameter(param.address);
    };
    
    // A function to provide string representations of parameter values.
    _parameterTree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
        AUValue value = valuePtr == nil ? param.value : *valuePtr;
        
        return [NSString stringWithFormat:@"%.f", value];
    };
}

#pragma mark - AUAudioUnit Overrides

- (AUAudioFrameCount)maximumFramesToRender {
    return _kernel.maximumFramesToRender();
}

- (void)setMaximumFramesToRender:(AUAudioFrameCount)maximumFramesToRender {
    _kernel.setMaximumFramesToRender(maximumFramesToRender);
}

// If an audio unit has input, this getter returns an audio unit's audio input connection points.
// Subclassers need to override this property getter and return the same object every time.
- (AUAudioUnitBusArray *)inputBusses {
    return _inputBusArray;
}

// An audio unit's audio output connection points.
// Subclassers must override this property getter and should return the same object every time.
- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

- (void)setShouldBypassEffect:(BOOL)shouldBypassEffect {
    _kernel.setBypass(shouldBypassEffect);
}

- (BOOL)shouldBypassEffect {
    return _kernel.isBypassed();
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    const auto inputChannelCount = [self.inputBusses objectAtIndexedSubscript:0].format.channelCount;
    const auto outputChannelCount = [self.outputBusses objectAtIndexedSubscript:0].format.channelCount;
    
    if (outputChannelCount != inputChannelCount) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:kAudioUnitErr_FailedInitialization userInfo:nil];
        }
        // Notify the subclass that initialization wasn't successful.
        self.renderResourcesAllocated = NO;
        
        return NO;
    }
    _inputBus.allocateRenderResources(self.maximumFramesToRender);
    _kernel.setMusicalContextBlock(self.musicalContextBlock);
    _kernel.initialize(inputChannelCount, outputChannelCount, _outputBus.format.sampleRate);
    _processHelper = std::make_unique<AUProcessHelper>(_kernel, inputChannelCount, outputChannelCount);
    return [super allocateRenderResourcesAndReturnError:outError];
}

// Deallocate resources allocated in `allocateRenderResourcesAndReturnError`.
// Subclassers should call the superclass implementation.
- (void)deallocateRenderResources {
    
    // Deallocate your resources.
    _kernel.deInitialize();
    
    [super deallocateRenderResources];
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

// A block that subclassers must provide to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
    // Specify that captured objects are mutable.
    __block vDSP_audio_unitExtensionDSPKernel *kernel = &_kernel;
    __block std::unique_ptr<AUProcessHelper> &processHelper = _processHelper;
    __block BufferedInputBus *input = &_inputBus;
    
    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags 				*actionFlags,
                              const AudioTimeStamp       				*timestamp,
                              AVAudioFrameCount           				frameCount,
                              NSInteger                   				outputBusNumber,
                              AudioBufferList            				*outputData,
                              const AURenderEvent        				*realtimeEventListHead,
                              AURenderPullInputBlock __unsafe_unretained pullInputBlock) {
        
        AudioUnitRenderActionFlags pullFlags = 0;
        
        if (frameCount > kernel->maximumFramesToRender()) {
            return kAudioUnitErr_TooManyFramesToProcess;
        }
        
        AUAudioUnitStatus err = input->pullInput(&pullFlags, timestamp, frameCount, 0, pullInputBlock);
        
        if (err != 0) { return err; }
        
        AudioBufferList *inAudioBufferList = input->mutableAudioBufferList;
        
        /*
         Important:
         If the caller passed non-null output pointers (`outputData->mBuffers[x].mData`), use those.
         
         If the caller passed `null` output buffer pointers, process in the memory owned by the audio unit
         and modify the (`outputData->mBuffers[x].mData`) pointers to point to this owned memory.
         The Audio Unit is responsible for preserving the validity of this memory until the next call to render,
         or `deallocateRenderResources` is called.
         
         If your algorithm can't process in-place, you will need to preallocate an output buffer
         and use it here.
         
         See the description of the `canProcessInPlace` property.
         */
        
        // If passed null output buffer pointers, process in-place in the input buffer.
        AudioBufferList *outAudioBufferList = outputData;
        if (outAudioBufferList->mBuffers[0].mData == nullptr) {
            for (UInt32 i = 0; i < outAudioBufferList->mNumberBuffers; ++i) {
                outAudioBufferList->mBuffers[i].mData = inAudioBufferList->mBuffers[i].mData;
            }
        }
        
        processHelper->processWithEvents(inAudioBufferList, outAudioBufferList, timestamp, frameCount, realtimeEventListHead);
        return noErr;
    };
}

@end

