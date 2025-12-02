/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the Metal 4 renderer's methods that set up the render's resources.
*/

#if !TARGET_OS_SIMULATOR

#import "Metal4Renderer+Setup.h"
#import "TriangleData.h"

@implementation Metal4Renderer (Setup)

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

/// Creates a new argument table from the renderer's device that stores two arguments.
- (id<MTL4ArgumentTable>) makeArgumentTable
{
    NSError *error = nil;

    // Configure the settings for a new argument table with two buffer bindings.
    MTL4ArgumentTableDescriptor *argumentTableDescriptor;
    argumentTableDescriptor = [MTL4ArgumentTableDescriptor new];
    argumentTableDescriptor.maxBufferBindCount = 2;

    // Create the argument table.
    id<MTL4ArgumentTable> argumentTable;
    argumentTable = [self.device newArgumentTableWithDescriptor:argumentTableDescriptor
                                                          error:&error];

    [self check:argumentTable name:@"argument table" number:-1 error:error];
    return argumentTable;
}

/// Returns a new residency set from the renderer's device.
- (id<MTLResidencySet>) makeResidencySet
{
    NSError *error = nil;

    // Create all residency sets with the same default configuration.
    MTLResidencySetDescriptor *residencySetDescriptor;
    residencySetDescriptor = [MTLResidencySetDescriptor new];

    // Create a long-term residency set for resources that the app needs for every frame.
    id<MTLResidencySet> residencySet;
    residencySet = [self.device newResidencySetWithDescriptor:residencySetDescriptor
                                                        error:&error];

    [self check:residencySet name:@"residency set" number:-1 error:error];

    return residencySet;
}

/// Creates new command allocator instances from the renderer's device and returns them in a new array.
/// - Parameter count: The number of allocators the method creates.
- (nonnull NSArray<id<MTL4CommandAllocator>> *) makeCommandAllocators:(NSUInteger) count
{
    NSMutableArray<id<MTL4CommandAllocator>> *allocatorArray;
    allocatorArray = [[NSMutableArray alloc] initWithCapacity:count];
    for (uint allocatorNumber = 0; allocatorNumber < count; allocatorNumber += 1)
    {
        id<MTL4CommandAllocator> allocator;
        allocator = [self.device newCommandAllocator];
        [self check:allocator name:@"command allocator" number:allocatorArray.count error:nil];

        [allocatorArray addObject:allocator];
    }
    return allocatorArray;
}

/// Reports when a resource isn't valid by asserting with a message.
///
/// - Parameters:
///   - resource: An pointer to a resource.
///   - name: A simple name or description of what `resource` is.
///   - number: When `resources` is part of a series, its position in that series; otherwise a negative number.
///   - error: A pointer to an optional error instance when applicable; otherwise `nil`.
- (void) check:(id) resource
          name:(nonnull NSString *) name
        number:(long) number
         error:(nullable NSError *) error
{
    if (nil != resource) { return ;}

    NSMutableString *errorString;
    errorString = [NSMutableString stringWithString:@"The Metal 4 device can't create"];
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

#endif
