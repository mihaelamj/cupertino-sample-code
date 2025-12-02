/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structure for representing an iTunes item.
*/

@import Foundation;

@interface Product : NSObject
/// The title  of the product.
@property (nonatomic, copy) NSString *title;
/// The iTunes identifier of the product.
@property (nonatomic, copy) NSString *productIdentifier;
/// Indicates whether the product is an app.
@property (nonatomic) BOOL isApplication;
/// The App Analytics campaign token.
@property (nonatomic, copy) NSString *campaignToken;
/// The App Analytics provider token.
@property (nonatomic, copy) NSString *providerToken;

-(instancetype)initWithTitle:(NSString *)title productIdentifier:(NSString *)productIdentifier isApplication:(BOOL)isApplication campaignToken:(NSString *)campaignToken providerToken:(NSString *)providerToken NS_DESIGNATED_INITIALIZER;

@end
