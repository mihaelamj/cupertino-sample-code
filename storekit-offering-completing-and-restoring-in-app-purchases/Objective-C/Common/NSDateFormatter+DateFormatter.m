/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A date formatter class category.
*/

#import "NSDateFormatter+DateFormatter.h"

@implementation NSDateFormatter (DateFormatter)
/// - returns: A date formatter with short time and date style.
+(NSDateFormatter *)shortStyle {
    NSDateFormatter *myDateFormatter = [[NSDateFormatter alloc] init];
    myDateFormatter.dateStyle = NSDateFormatterShortStyle;
    myDateFormatter.timeStyle = NSDateFormatterShortStyle;
    return myDateFormatter;
}

/// - returns: A date formatter with long time and date style.
+(NSDateFormatter *)longStyle {
    NSDateFormatter *myDateFormatter = [[NSDateFormatter alloc] init];
    myDateFormatter.dateStyle = NSDateFormatterLongStyle;
    myDateFormatter.timeStyle = NSDateFormatterLongStyle;
    return myDateFormatter;
}

@end
