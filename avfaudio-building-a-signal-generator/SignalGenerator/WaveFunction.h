/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The functions that produce classic waveforms.
*/

#pragma once

// A WaveFunction is a function pointer type that takes a float and an int, and returns a float.
typedef float (*WaveFunction)(float, int);

inline float sine(float phase, int) {
    return sin(phase);
}

inline float additiveSawtooth(float phase, int harmonics) {
    float sample = 0;
    
    for (int i = 1; i <= harmonics; ++i)
        sample += sin(i * phase) / i;
    
    return (2.0f / M_PI) * sample;
}

inline float additiveSquare(float phase, int harmonics) {
    float sample = 0;
    
    for (int i = 1; i <= harmonics; i += 2)
        sample += sin(i * phase) / i;
    
    return (4.0f / M_PI) * sample;
}

inline float additiveTriangle(float phase, int harmonics) {
    float sample = 0;
    
    for (int i = 1; i <= harmonics; i += 2)
        sample += powf(-1, (i - 1) / 2) * sin(i * phase) / (i * i);
    
    return (8.0f / (M_PI * M_PI)) * sample;
}

inline float whiteNoise(float, int) {
    return float(arc4random_uniform(UINT32_MAX)) / float(UINT32_MAX) * 2.0f - 1.0f;
}
