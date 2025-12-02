/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the Metal renderer's methods that set up the render's resources.
*/

#import "MetalRenderer+Setup.h"
#import "TriangleData.h"

@implementation MetalRenderer (Setup)

/// Creates new buffer instances for triangle data from the renderer's device
/// and returns them in a new array.
/// - Parameter count: The number of buffers the method creates.
- (nonnull NSArray<id<MTLBuffer>> *) makeTriangleDataBuffers:(NSUInteger) count
{
    NSMutableArray<id<MTLBuffer>> *bufferArray;
    bufferArray = [[NSMutableArray alloc] initWithCapacity:count];
    for (uint bufferNumber = 0; bufferNumber < count; bufferNumber += 1) {
        id<MTLBuffer> buffer;
        // Create the buffer that stores the triangle's vertex data.
        buffer = [self.device newBufferWithLength:sizeof(TriangleData)
                                          options:MTLResourceStorageModeShared];

        [self check:buffer name:@"buffer" number:bufferArray.count error:nil];
        [bufferArray addObject:buffer];
    }

    return bufferArray;
}

/// Reports when a resource isn't valid by asserting with a message.
///
/// - Parameters:
///   - resource: An pointer to a resource.
///   - name: A simple name or description of what `resource` is.
///   - number: When `resource` is part of a series, its position in that series; otherwise a negative number.
///   - error: A pointer to an optional error instance when applicable; otherwise `nil`.
- (void) check:(id) resource
          name:(nonnull NSString *) name
        number:(long) number
         error:(nullable NSError *) error
{
    if (nil != resource) { return ;}

    NSMutableString *errorString;
    errorString = [NSMutableString stringWithString:@"The Metal device can't create"];
    [errorString appendFormat: @" %@", name];

    if (number >= 0) {
        [errorString appendFormat: @ "%ld", number];
    }

    if (error != nil) {
        [errorString appendFormat: @": %@\n", error];
    }
    else {
        [errorString appendString:@"."];
    }

    NSAssert(false, errorString);
}

@end
