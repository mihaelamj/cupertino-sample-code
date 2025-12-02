/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The signal generator manages interaction with the processing kernel and provides a render block that can be used to construct an audio source node.
*/

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef CF_ENUM(unsigned, Waveform) {
    kWaveformSine,
    kWaveformSawtooth,
    kWaveformSquare,
    kWaveformTriangle,
    kWaveformNoise
};

@interface SignalGenerator : NSObject

// The block this class provides to implement rendering. Similar to `AUInternalRenderBlock`.
@property (nonatomic, readonly) AVAudioSourceNodeRenderBlock renderBlock;

- (void)setSampleRate:(double)sampleRate;

- (void)setFrequency:(float)frequency;

- (void)setAmplitude:(float)amplitude;

- (void)setWaveform:(Waveform)waveform;

@end

NS_ASSUME_NONNULL_END
