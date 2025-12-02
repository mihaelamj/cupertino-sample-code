/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the cross-platform game view controller.
*/

#import <Metal/Metal.h>
#import "Renderer.h"
#import "GameView.h"

#if TARGET_IOS || TARGET_TVOS
#import <UIKit/UIKit.h>
#define PlatformViewController UIViewController
#else
#import <AppKit/AppKit.h>
#define PlatformViewController NSViewController
#endif

@interface GameViewController : PlatformViewController <GameViewDelegate>

@end
