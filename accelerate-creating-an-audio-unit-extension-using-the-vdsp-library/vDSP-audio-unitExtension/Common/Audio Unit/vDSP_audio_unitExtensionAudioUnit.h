/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit extension header.
*/

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface vDSP_audio_unitExtensionAudioUnit : AUAudioUnit
- (void)setupParameterTree:(AUParameterTree *)parameterTree;
@end
