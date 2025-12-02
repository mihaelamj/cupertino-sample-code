/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A date formatter class category.
*/

@import Foundation;

@interface NSDateFormatter (DateFormatter)
/// - returns: A date formatter with short time and date style.
+(NSDateFormatter *)shortStyle;

/// - returns: A date formatter with long time and date style.
+(NSDateFormatter *)longStyle;
@end
