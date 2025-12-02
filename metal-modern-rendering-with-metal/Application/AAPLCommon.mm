/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implemenation of common application utilities.
*/
#import <Foundation/Foundation.h>

#import "AAPLCommon.h"

NSUInteger alignUp(const NSUInteger value, const NSUInteger alignment)
{
    return (value + (alignment - 1)) & ~(alignment-1);
}

NSUInteger divideRoundUp(const NSUInteger& numerator, const NSUInteger& denominator)
{
    // Will break when `numerator+denominator > uint_max`.
    assert(numerator <= UINT32_MAX - denominator);

    return (numerator + denominator - 1) / denominator;
}

MTLSize divideRoundUp(const MTLSize& numerator, const MTLSize& denominator)
{
    return (MTLSize)
    {
        divideRoundUp(numerator.width,  denominator.width),
        divideRoundUp(numerator.height, denominator.height),
        divideRoundUp(numerator.depth,  denominator.depth)
    };
}

//-----------------------------------------
//-----------------------------------------
//-----------------------------------------

NSString* getAppName()
{
    NSString* bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (bundleName == nil)
    {
        bundleName = [NSString stringWithUTF8String:getprogname()];
    }
    return bundleName;
}

NSString* getOrCreateApplicationSupportPath()
{
    NSArray* asdRoots = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    assert(asdRoots.count != 0);

    NSString* asdRoot = asdRoots [0];
    NSString* asdPath = [asdRoot stringByAppendingFormat:@"/%@", getAppName()];

    NSError* error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:asdPath
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&error];
    NSCAssert(success, @"Failed to obtain application support directory at %@: %@",
              asdPath, error);

    if(!success)
    {
        asdPath = nil;
    }

    return asdPath;
}

id<MTLComputePipelineState> newComputePipelineState(id<MTLLibrary> library,
                                                    NSString *functionName,
                                                    NSString *label,
                                                    MTLFunctionConstantValues *functionConstants)
{
    NSError *error;

    id<MTLComputePipelineState> returnPipeline;

    MTLComputePipelineDescriptor *descriptor = [MTLComputePipelineDescriptor new];
    descriptor.label = label;

    MTLFunctionDescriptor *functionDescriptor = [MTLFunctionDescriptor new];
    functionDescriptor.name           = functionName;
    if(functionConstants)
    {
        functionDescriptor.constantValues = functionConstants;
    }

    descriptor.computeFunction = [library newFunctionWithDescriptor:functionDescriptor error:&error];

    NSCAssert(descriptor.computeFunction, @"Failed to create Metal kernel function %@: %@", functionName, error);

    returnPipeline = [library.device newComputePipelineStateWithDescriptor:descriptor
                                                                   options:MTLPipelineOptionNone
                                                                reflection:nil
                                                                     error:&error];

    NSCAssert(returnPipeline, @"Failed to create compute pipeline state %@: %@", functionName, error);

    return returnPipeline;
}
