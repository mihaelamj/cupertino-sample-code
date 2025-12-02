/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Declaration of the app delegate object.
*/

#import "TargetConditionals.h"
#import "AAPLAppDelegate.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#if TARGET_OS_IOS

int main(int argc, char* argv[])
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AAPLAppDelegate class]));
    }
}

#elif TARGET_OS_OSX

int main(int argc, const char* argv[])
{
    return NSApplicationMain(argc, argv);
}

#endif
