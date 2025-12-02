/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A simple actor class that stores data for a quad mesh instance.
*/

#import "AAPLActor.h"

@implementation AAPLActor

-(instancetype) initWithProperties:(vector_float4) color
                          position:(vector_float3) position
                          rotation:(vector_float3) rotation
                             scale:(vector_float3) scale
{
    self = [super init];
    
    if (self != nil)
    {
        _color = color;
        _position = position;
        _rotation = rotation;
        _scale = scale;
    }
    return self;
}

@end
