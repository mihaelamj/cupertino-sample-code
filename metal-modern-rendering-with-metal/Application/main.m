/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Application Entrypoint.
*/
#import "AAPLAppDelegate.h"

int main(int argc, char * argv[])
{
    @autoreleasepool
    {
#if TARGET_OS_IPHONE
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AAPLAppDelegate class]));
#else
        return NSApplicationMain (argc, (const char* _Nonnull * _Nonnull) argv);
#endif
    }
}
