/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interface of the app's view controller.
*/
#import "TargetConditionals.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#define PlatformViewController UIViewController<MTKViewDelegate>
#else
#import <Cocoa/Cocoa.h>
#define PlatformViewController NSViewController<MTKViewDelegate>
#endif

@interface AAPLViewController : PlatformViewController
@end

