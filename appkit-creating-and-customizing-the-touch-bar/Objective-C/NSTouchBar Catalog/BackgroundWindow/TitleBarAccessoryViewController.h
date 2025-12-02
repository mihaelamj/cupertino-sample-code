/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller for the title bar accessory that contains the Set Background button.
*/

#import <Cocoa/Cocoa.h>

@class BackgroundImagesViewController;

@interface TitleBarAccessoryViewController : NSTitlebarAccessoryViewController

@property (nonatomic, strong) BackgroundImagesViewController *openingViewController;

@end
