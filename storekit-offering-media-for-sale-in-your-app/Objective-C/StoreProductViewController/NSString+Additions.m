/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A category for string objects.
*/

#import "NSString+Additions.h"

@implementation NSString (Additions)
-(BOOL)exists {
    return (self != nil) && ([self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0);
}
@end
