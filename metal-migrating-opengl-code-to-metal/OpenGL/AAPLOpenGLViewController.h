/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the cross-platform view controller and cross-platform view that displays OpenGL content.
*/

#if defined(TARGET_IOS) || defined(TARGET_TVOS)
@import UIKit;
#define PlatformViewBase UIView
#define PlatformViewController UIViewController
#else
@import AppKit;
#define PlatformViewBase NSOpenGLView
#define PlatformViewController NSViewController
#endif

@interface AAPLOpenGLView : PlatformViewBase

@end

@interface AAPLOpenGLViewController : PlatformViewController

@end
