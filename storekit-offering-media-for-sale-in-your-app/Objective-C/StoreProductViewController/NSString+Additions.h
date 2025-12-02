/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A category for string objects.
*/

@import Foundation;

NS_ASSUME_NONNULL_BEGIN
@interface NSString (Additions)
/// Indicates whether the string has a value.
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL exists;
@end
NS_ASSUME_NONNULL_END
