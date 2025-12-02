/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Event wrapper protocol and class providing basic synchronization routines to facilitate encoders ordering. On signaling it advances the internal counter for integrity.
*/

#ifndef AAPLEventWrapper_h
#define AAPLEventWrapper_h

@import Metal;

@protocol AAPLEventWrapper

- (nonnull instancetype) initWithDevice:(nonnull id <MTLDevice>)device;

- (void) wait:(_Nonnull id <MTLCommandBuffer>)commandBuffer;
- (void) signal:(_Nonnull id <MTLCommandBuffer>)commandBuffer;

@end

// Single device event wrapper
@interface AAPLSingleDeviceEventWrapper : NSObject <AAPLEventWrapper>
@end

#endif /* APPLEventWrapper_h */

