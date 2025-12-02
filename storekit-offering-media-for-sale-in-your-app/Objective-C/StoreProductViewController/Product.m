/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structure for representing an iTunes item.
*/

#import "Product.h"

@implementation Product
-(instancetype)init {
    return [self initWithTitle:nil productIdentifier:nil isApplication:NO campaignToken:nil providerToken:nil];
}

-(instancetype)initWithTitle:(NSString *)title productIdentifier:(NSString *)productIdentifier isApplication:(BOOL)isApplication campaignToken:(NSString *)campaignToken providerToken:(NSString *)providerToken {
    self = [super init];
    if (self != nil) {
        _title = [title copy];
        _productIdentifier = [productIdentifier copy];
        _isApplication = isApplication;
        _campaignToken = [campaignToken copy];
        _providerToken = [providerToken copy];
    }
    return self;
}
@end
