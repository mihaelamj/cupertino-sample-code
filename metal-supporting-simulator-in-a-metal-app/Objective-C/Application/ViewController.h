
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the cross-platform view controller.
*/

#if defined(TARGET_IOS) || defined(TARGET_TVOS)
@import UIKit;
#define PlatformViewController UIViewController
#else
@import AppKit;
#define PlatformViewController NSViewController
#endif

@import MetalKit;

@interface ViewController : PlatformViewController

#ifdef TARGET_IOS
@property (weak, nonatomic) IBOutlet UISlider *transparencySlider;
@property (weak, nonatomic) IBOutlet UISegmentedControl *blendMode;
#endif

@end
