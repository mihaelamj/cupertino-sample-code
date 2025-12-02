/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A product class category.
*/

@import StoreKit;

@interface SKProduct (SKProductAdditions)
/// - returns: The cost of the product formatted in the local currency.
-(NSString *)regularPrice;
@end
