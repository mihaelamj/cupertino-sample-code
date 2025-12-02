/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for tne application delegate class.
*/

#import <Foundation/Foundation.h>
#import "TargetConditionals.h"

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface AAPLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

#else

#import <Cocoa/Cocoa.h>

@interface AAPLAppDelegate : NSObject <NSApplicationDelegate>

@end

#endif
