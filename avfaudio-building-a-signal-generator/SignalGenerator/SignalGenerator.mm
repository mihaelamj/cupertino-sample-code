/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The signal generator's implementation wraps around the C++ processing kernel and defines the render block.
*/

#import "SignalGenerator.h"
#include "SignalGeneratorKernel.h"

#import <AudioToolbox/AudioToolbox.h>

struct SignalGeneratorParameters {
    float frequency = 440.0f;
    float amplitude = -12.0f;
    Waveform waveform = kWaveformSine;
};

@implementation SignalGenerator {
    // C++ members need to be ivars; they would be copied on access if they were properties.
    SignalGeneratorKernel _kernel;
    SignalGeneratorParameters _parameters;
}

- (void)setSampleRate:(double)sampleRate {
    // Initialize the kernel with the sample rate while the engine is stopped.
    _kernel.setSampleRate(sampleRate);
}

- (void)setFrequency:(float)frequency {
    // Store the frequency. The kernel will be updated in the next render operation.
    _parameters.frequency = frequency;
}

- (void)setAmplitude:(float)amplitude {
    // Store the amplitude. The kernel will be updated in the next render operation.
    _parameters.amplitude = amplitude;
}

- (void)setWaveform:(Waveform)waveform {
    // Store the waveform. The kernel will be updated in the next render operation.
    _parameters.waveform = waveform;
}

- (AVAudioSourceNodeRenderBlock)renderBlock {
    // Capture in locals to avoid capturing "self" in render, leading to Objective-C member lookups.
    // Specify captured objects are mutable.
    __block SignalGeneratorKernel *kernel = &_kernel;
    __block SignalGeneratorParameters *parameters = &_parameters;
    
    return ^OSStatus(BOOL *isSilence,
                     const AudioTimeStamp *timestamp,
                     AVAudioFrameCount frameCount,
                     AudioBufferList *outputData) {
        // Update the signal generator parameters once per render operation.
        kernel->update(parameters->waveform, parameters->amplitude, parameters->frequency);
        
        for (auto frame = 0; frame < frameCount; ++frame) {
            // Get the signal value for this frame at time.
            auto value = kernel->getNextSample();
            
            // Copy the signal value to all channels.
            for (auto buffer = 0; buffer < outputData->mNumberBuffers; ++buffer) {
                auto *channel = static_cast<float *>(outputData->mBuffers[buffer].mData);
                channel[frame] = value;
            }
        }
        
        return noErr;
    };
}

@end
