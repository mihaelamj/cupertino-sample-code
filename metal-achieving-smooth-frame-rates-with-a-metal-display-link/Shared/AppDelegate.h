/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the cross-platform app delegate.
*/

#if TARGET_IOS || TARGET_TVOS
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#if TARGET_IOS || TARGET_TVOS
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property(strong, nonatomic) UIWindow *window;
#else
@interface AppDelegate : NSObject <NSApplicationDelegate>

@property(strong, nonatomic) IBOutlet NSWindow *window;
#endif
@end
