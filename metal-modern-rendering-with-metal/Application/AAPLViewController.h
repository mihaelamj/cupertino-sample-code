/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller.
*/

#import <Foundation/Foundation.h>
#import "TargetConditionals.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import <MetalKit/MetalKit.h>

@interface AAPLView : MTKView
- (BOOL)acceptsFirstResponder;
#if !TARGET_OS_IPHONE
- (BOOL)acceptsFirstMouse:(NSEvent *)event;
#endif

@end

#if TARGET_OS_IPHONE
@interface AAPLViewController : UIViewController<MTKViewDelegate>
@end

#else

@interface AAPLViewController : NSViewController<MTKViewDelegate>
@end
#endif
