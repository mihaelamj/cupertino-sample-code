/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller for managing products available for sale, invalid product
 identifiers, purchases, and messages.
*/

@import Cocoa;

@interface MainViewController : NSViewController
-(void)reloadViewController:(NSString *)viewController;
-(void)reloadViewController:(NSString *)viewController withMessage:(NSString*)message;
@end
