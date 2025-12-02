/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A product class category.
*/

#import "SKProduct+SKProductAdditions.h"

@implementation SKProduct (SKProductAdditions)
/// - returns: The cost of the product formatted in the local currency.
-(NSString *)regularPrice {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: self.priceLocale];
    return [formatter stringFromNumber:self.price];
}

@end
