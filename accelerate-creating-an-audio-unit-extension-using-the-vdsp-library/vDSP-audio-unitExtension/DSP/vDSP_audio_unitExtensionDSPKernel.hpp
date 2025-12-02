/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit digital signal-processing file.
*/


#pragma once

#import <AudioToolbox/AudioToolbox.h>
#import <algorithm>
#import <vector>
#import <span>

#import <Accelerate/Accelerate.h>

#import "vDSP_audio_unitExtension-Swift.h"
#import "vDSP_audio_unitExtensionParameterAddresses.h"

/// A structure that contains a single-channel `vDSP_biquad_Setup` object
/// and the past state data.
struct Biquad {
    vDSP_biquad_Setup setup;
    float delay[4];
};

/*
 vDSP_audio_unitExtensionDSPKernel
 As a non-ObjC class, this is safe to use from render thread.
 */
/// - Tag: vDSP_audio_unitExtensionDSPKernel
class vDSP_audio_unitExtensionDSPKernel {
    
    /// A vector of `inputChannelCount` `Biquad` structures.
    std::vector <Biquad> biquads;
    
public:
    
    /// Initializes the `vDSP_audio_unitExtensionDSPKernel`.
    void initialize(int inputChannelCount, int outputChannelCount, double inSampleRate) {
        mSampleRate = inSampleRate;

        // Default coefficients.
        double coefficients[5] = {1.0, 0.0, 0.0, 1.0, 0.0};
        
        for (int i = 0; i < inputChannelCount; i++) {
            
            biquads.push_back((Biquad){
                .setup = vDSP_biquad_CreateSetup(coefficients, 1)
            });
            
            for (int j = 0; j < 4; j++) {
                biquads[i].delay[j] = 0.0;
            }
        }
    }
    
    /// Deinitializes the `vDSP_audio_unitExtensionDSPKernel`.
    void deInitialize() {
        
        for (int i = 0; i < biquads.size() ; i++) {
            vDSP_biquad_DestroySetup(biquads[i].setup);
        }
    }
    
    // MARK: - Bypass
    bool isBypassed() {
        return mBypassed;
    }
    
    void setBypass(bool shouldBypass) {
        mBypassed = shouldBypass;
    }
    
    // MARK: - Parameter Getter / Setter
    void setParameter(AUParameterAddress address, AUValue value) {
        switch (address) {
            case vDSP_audio_unitExtensionParameterAddress::frequency:
                frequency = value;
                break;
            case vDSP_audio_unitExtensionParameterAddress::Q:
                Q = value;
                break;
            case vDSP_audio_unitExtensionParameterAddress::dbGain:
                dbGain = value;
                break;
        }
    }
    
    AUValue getParameter(AUParameterAddress address) {
        // Return the goal. It's not thread safe to return the ramping value.
        
        switch (address) {
            case vDSP_audio_unitExtensionParameterAddress::frequency:
                return (AUValue)frequency;
            case vDSP_audio_unitExtensionParameterAddress::Q:
                return (AUValue)Q;
            case vDSP_audio_unitExtensionParameterAddress::dbGain:
                return (AUValue)dbGain;
            default: return 0.f;
        }
    }
    
    // MARK: - Max Frames
    AUAudioFrameCount maximumFramesToRender() const {
        return mMaxFramesToRender;
    }
    
    void setMaximumFramesToRender(const AUAudioFrameCount &maxFrames) {
        mMaxFramesToRender = maxFrames;
    }
    
    // MARK: - Musical Context
    void setMusicalContextBlock(AUHostMusicalContextBlock contextBlock) {
        mMusicalContextBlock = contextBlock;
    }
    
    // MARK: - Internal Process
    
    /// Apply the peaking EQ biquadratic filter to each buffer in `inputBuffers` and write the result to the
    /// corresponding buffer in `outputBuffers`.
    /// - Tag: process
    void process(std::span<float const*> inputBuffers,
                 std::span<float *> outputBuffers,
                 AUEventSampleTime bufferStartTime,
                 AUAudioFrameCount frameCount) {
        
        if (mBypassed) {
            // Pass the samples through.
            for (UInt32 channel = 0; channel < inputBuffers.size(); ++channel) {
                std::copy_n(inputBuffers[channel], frameCount, outputBuffers[channel]);
            }
            return;
        }
        
        double coeffs[5];
        // Populate `coeffs` from the parameters.
        biquadCoefficientsFor(mSampleRate,
                              frequency,
                              Q,
                              dbGain,
                              coeffs);
        
        // For each channel, calculate and set the coefficients, and apply the
        // biquadratic filter.
        for (UInt32 channel = 0; channel < inputBuffers.size(); ++channel) {
                        
            // Set the coefficients on the biquadratic object.
            vDSP_biquad_SetCoefficientsDouble(biquads[channel].setup,
                                              coeffs,
                                              0, 1);
            
            // Apply the biquadratic filter.
            vDSP_biquad(biquads[channel].setup,
                        biquads[channel].delay,
                        inputBuffers[channel], 1,
                        outputBuffers[channel], 1,
                        frameCount);
        }
    }
    
    /// Calculates the biquadratic filter coefficients for a given frequency, Q, and decibel gain.
    void biquadCoefficientsFor(double sampleRate,
                               double frequency,
                               double Q,
                               double dbGain,
                               double* coeffs)  {
        
        double omega = 2.0 * M_PI * frequency / sampleRate;
        double sinOmega = sin(omega);
        double alpha = sinOmega / ((2 * Q));
        double cosOmega = cos(omega);
        
        double A = pow(10.0, dbGain / 40);
        
        double b0 = 1 + alpha * A;
        double b1 = -2 * cosOmega;
        double b2 = 1 - alpha * A;
        double a0 = 1 + alpha / A;
        double a1 = -2 * cosOmega;
        double a2 = 1 - alpha / A;
        
        coeffs[0] = b0 / a0;
        coeffs[1] = b1 / a0;
        coeffs[2] = b2 / a0;
        coeffs[3] = a1 / a0;
        coeffs[4] = a2 / a0;
    }
    
    void handleOneEvent(AUEventSampleTime now, AURenderEvent const *event) {
        switch (event->head.eventType) {
            case AURenderEventParameter: {
                handleParameterEvent(now, event->parameter);
                break;
            }
                
            default:
                break;
        }
    }
    
    void handleParameterEvent(AUEventSampleTime now, AUParameterEvent const& parameterEvent) {
        // Implement handling incoming parameter events as needed.
    }
    
    // MARK: Member Variables
    AUHostMusicalContextBlock mMusicalContextBlock;
    
    double mSampleRate = 44100.0;
    double frequency = 100;
    double Q = 0.0;
    double dbGain = 0.0;
    bool mBypassed = false;
    AUAudioFrameCount mMaxFramesToRender = 1024;
};
