/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A base class to allow for pure Objective-C++ access to realtime DSP code.
*/


#import <AudioToolbox/AudioToolbox.h>
#import <AUv3FilterFramework/FilterDSPKernelAdapter.h>

NS_ASSUME_NONNULL_BEGIN

@interface AUv3Base : AUAudioUnit
@property (nonatomic, readonly) FilterDSPKernelAdapter * kernelAdapter;
- (void)setupAudioBuses;
@end

NS_ASSUME_NONNULL_END
