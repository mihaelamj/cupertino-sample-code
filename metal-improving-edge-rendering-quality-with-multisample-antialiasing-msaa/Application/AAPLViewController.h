/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the cross-platform view controller.
*/
#pragma once

#if TARGET_IOS || TARGET_TVOS

@import UIKit;

#define PlatformViewController UIViewController
#if TARGET_IOS
#define PlatformButton           UISwitch
#elif TARGET_TVOS
#define PlatformButton           UIButton
#endif
#define PlatformGroupView        UIStackView
#define PlatformSegmentedControl UISegmentedControl

#elif TARGET_MACOS

@import AppKit;
@import Carbon;

#define PlatformViewController   NSViewController
#define PlatformButton           NSButton
#define PlatformGroupView        NSGridView
#define PlatformSegmentedControl NSSegmentedControl

#endif

@import MetalKit;

@interface AAPLViewController : PlatformViewController <MTKViewDelegate>

@property (weak) IBOutlet PlatformButton *antialasingToggle;
@property (weak) IBOutlet PlatformGroupView *msaaOptionsGroupView;

@property (weak) IBOutlet PlatformSegmentedControl *antialiasingSampleCountSegments;
@property (weak) IBOutlet PlatformSegmentedControl *antialiasingResolveOptionSegments;
@property (weak) IBOutlet PlatformSegmentedControl *resolvePathSegments;
@property (weak) IBOutlet PlatformSegmentedControl *renderingQualitySegments;

- (IBAction)toggleAntialiasing:(PlatformButton*)sender;

- (IBAction)updateAntialiasingSampleCount:(PlatformSegmentedControl*)sender;
- (IBAction)updateAntialiasingResolve:(PlatformSegmentedControl*)sender;
- (IBAction)changeResolvePath:(PlatformSegmentedControl*)sender;
- (IBAction)changeRenderingQuality:(PlatformSegmentedControl*)sender;

@end
