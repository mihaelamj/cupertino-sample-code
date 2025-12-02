/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application's entry point for all platforms.
*/

#import "AAPLAppDelegate.h"

#if defined(TARGET_MACOS)

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        return NSApplicationMain(argc, argv);
    }
}

#elif defined(TARGET_IOS) || defined (TARGET_TVOS)

#if TARGET_OS_SIMULATOR && !defined(__IPHONE_13_0)
#error No simulator support for Metal API for this SDK version.  Must build for a device
#endif

int main(int argc, char * argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AAPLAppDelegate class]));
    }
}

#endif
