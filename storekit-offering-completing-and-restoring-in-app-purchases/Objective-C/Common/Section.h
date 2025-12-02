/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structure for representing a list of products or purchases.
*/

@import Foundation;

@interface Section : NSObject
/// The system organizes products and purchases by category.
@property (nonatomic, copy) NSString *name;

/// The list of products and purchases.
@property (strong) NSArray *elements;

/// Create a Section object.
-(instancetype)initWithName:(NSString *)name elements:(NSArray *)elements NS_DESIGNATED_INITIALIZER;
@end
