/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app entry point for all platforms.
*/

#if TARGET_IOS || TARGET_TVOS
#import <UIKit/UIKit.h>
#import <TargetConditionals.h>
#import "AAPLAppDelegate.h"
#elif TARGET_MACOS
#import <Cocoa/Cocoa.h>
#endif

#if TARGET_IOS || TARGET_TVOS

int main(int argc, char * argv[])
{
    
#if TARGET_OS_SIMULATOR && TBDR_RESOLVE
#error This sample doesn't support Simulator with the tile-based resolve enabled. \
You must build for an A11 device or later or comment out the TBDR_RESOLVE define in the AAPLConfig.h file.
#endif
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AAPLAppDelegate class]));
    }
}

#elif TARGET_MACOS

int main(int argc, const char * argv[])
{
    return NSApplicationMain(argc, argv);
}

#endif
