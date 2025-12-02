/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structure for representing a list of products or purchases.
*/

#import "Section.h"

@implementation Section

-(instancetype)init {
    return [self initWithName:nil elements:@[]];
}

-(instancetype)initWithName:(NSString *)name elements:(NSArray *)elements {
    self = [super init];
    
    if(self != nil) {
        _name = [name copy];
        _elements = elements;
    }
    return self;
}
@end
