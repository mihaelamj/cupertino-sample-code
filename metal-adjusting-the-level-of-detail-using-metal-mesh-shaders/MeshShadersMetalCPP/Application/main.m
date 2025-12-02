/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's entry point for each platform.
*/

#import <TargetConditionals.h>
#import "AAPLAppDelegate.h"

#if TARGET_OS_OSX

int main(int argc, const char* argv[])
{
    return NSApplicationMain(argc, argv);
}

#elif TARGET_OS_IPHONE

int main(int argc, char* argv[])
{
    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AAPLAppDelegate class]));
}

#endif
