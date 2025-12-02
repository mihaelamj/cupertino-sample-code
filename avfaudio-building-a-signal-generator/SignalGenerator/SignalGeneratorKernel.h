/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The processing kernel manages the state of the signal generator. It is a C++ class that is safe to use in a real-time render block.
*/

#pragma once

#include "WaveFunction.h"
#include "ParameterRamp.h"

#define TWO_PI float(2.0 * M_PI)

class SignalGeneratorKernel {
public:
    void setSampleRate(float inSampleRate) {
        // Store the sample rate.
        sampleRate = inSampleRate;
        // Update the maximum number of harmonics by taking the floor of the Nyquist frequency divided by the base frequency.
        numHarmonics = int(0.5f * sampleRate / frequency);
        // Set the phase increment ramp length to 100 milliseconds.
        phaseIncrement.setRampLength(0.1f * sampleRate);
        // Set the raw amplitude ramp length to 100 milliseconds.
        rawAmplitude.setRampLength(0.1f * sampleRate);
    }
    
    void update(Waveform inWaveform, float inAmplitude, float inFrequency) {
        // Store the waveform.
        currentWaveform = inWaveform;
        
        if (amplitude != inAmplitude) {
            // Store the amplitude.
            amplitude = inAmplitude;
            // The inAmplitude parameter is converted from decibels to a raw amplitude value. The raw amplitude needs to be ramped to avoid artifacts.
            rawAmplitude.setTargetValue(powf(10, inAmplitude * 0.05f));
        }
        
        if (frequency != inFrequency) {
            // Store the frequency.
            frequency = inFrequency;
            // Update the maximum number of harmonics by taking the floor of the Nyquist frequency divided by the base frequency.
            numHarmonics = int(0.5f * sampleRate / frequency);
            // The phase increment needs to be ramped to avoid artifacts.
            phaseIncrement.setTargetValue(frequency * TWO_PI / sampleRate);
        }
    }
    
    float getNextSample() {
        // Get the function pointer to the selected waveform.
        auto waveform = waveFunctions[currentWaveform];
        // Get the next sample.
        auto sample = waveform(phase, numHarmonics);
        
        // Advance the phase for the next frame.
        phase += phaseIncrement.getNextValue();
        
        // Wrap the phase between 0 and 2π.
        if (phase >= TWO_PI)
            phase -= TWO_PI;
        
        // Return the next sample scaled by the raw amplitude.
        return sample * rawAmplitude.getNextValue();
    }
    
private:
    // An array of function pointers to the classic waveforms.
    WaveFunction waveFunctions[5] = {sine, additiveSawtooth, additiveSquare, additiveTriangle, whiteNoise};
    // The current waveform in an index into the `waveFunctions` array.
    Waveform currentWaveform = kWaveformSine;
    // The sample rate is used to compute the phase increment when the generator frequency changes.
    float sampleRate = 44100.0f;
    // The current generator amplitude in decibels.
    float amplitude = -12.0f;
    // The current generator frequency in hertz.
    float frequency = 440.0f;
    // The current phase in radians.
    float phase = 0.0f;
    // The maximum number of harmonics given the current frequency and sample rate.
    int numHarmonics = 1;
    // The interval to advance the phase each frame.
    ParameterRamp phaseIncrement{frequency * TWO_PI / sampleRate};
    // The raw amplitude value that is multiplied to every sample.
    ParameterRamp rawAmplitude{0.25f};
};
