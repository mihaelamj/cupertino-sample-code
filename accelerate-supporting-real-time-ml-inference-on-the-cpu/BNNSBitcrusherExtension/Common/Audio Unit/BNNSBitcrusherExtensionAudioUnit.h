/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher `AUAudioUnit` extension header.
*/
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface BNNSBitcrusherExtensionAudioUnit : AUAudioUnit
- (void)setupParameterTree:(AUParameterTree *)parameterTree;
@end
