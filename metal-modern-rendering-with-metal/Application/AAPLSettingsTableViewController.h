/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the controller managing the table view UI.
*/

#import <Foundation/Foundation.h>
#import "TargetConditionals.h"

#import "AAPLConfig.h"

#if SUPPORT_ON_SCREEN_SETTINGS

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^SettingsCallback)(void);

@interface AAPLSettingsTableViewController : UITableViewController<UITableViewDelegate, UITableViewDataSource>

- (void)addButton:(NSString*)label callback:(nullable SettingsCallback)callback;
- (void)addToggle:(NSString*)label value:(bool*)value callback:(nullable SettingsCallback)callback;
- (void)addSlider:(NSString*)label value:(float*)value min:(float)min max:(float)max;
- (void)addCombo:(NSString*)label options:(NSArray<NSString*>*)options value:(uint*)value callback:(nullable SettingsCallback)callback;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END

#endif // SUPPORT_ON_SCREEN_SETTINGS
