/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the cross-platform view controller.
*/

@import MetalKit;

#import "AAPLRenderer.h"

#if defined(TARGET_IOS)
@import UIKit;
@interface AAPLViewController : UIViewController // : UIResponder
#else
@import AppKit;
@interface AAPLViewController : NSViewController // : NSResponder
#endif

@end
