/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the iOS view controller.
*/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AAPLViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* loadingSpinner;
@property (nonatomic, weak) IBOutlet UILabel* loadingLabel;

@end

NS_ASSUME_NONNULL_END
