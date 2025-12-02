/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class which generates a depth pyramid (i.e. depth mipmaps) from a depth texture.
*/

#import "AAPLDepthPyramid.h"
#import "AAPLCommon.h"
#import "AAPLShaderTypes.h"


#import <simd/simd.h>
#import <Foundation/Foundation.h>

@implementation AAPLDepthPyramid
{
    // Device from initialization.
    id<MTLDevice> _device;

    // Depth downsampling pipeline state.
    id<MTLComputePipelineState> _pipelineState;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                               library:(nonnull id<MTLLibrary>)library
{
    self = [super init];
    if(self)
    {
        _device = device;
        _pipelineState = newComputePipelineState(library, @"depthPyramid", @"DepthPyramidGeneration", nil);
    }

    return self;
}

- (void)generate:(id<MTLTexture>)pyramidTexture
    depthTexture:(id<MTLTexture>)depthTexture
       onEncoder:(nonnull id<MTLComputeCommandEncoder>)encoder
{
    assert((depthTexture == pyramidTexture)                                     // Same texture
           || [AAPLDepthPyramid isPyramidTextureValidForDepth:pyramidTexture    // Or, valid for downsample
                                                 depthTexture:depthTexture]);

    [encoder pushDebugGroup:@"Depth pyramid generation"];

    [encoder setComputePipelineState:_pipelineState]; // `depthPyramid` kernel.

    id<MTLTexture> srcMip = depthTexture;
    uint startMip = 0;
    if(depthTexture == pyramidTexture)
    {
        srcMip = [pyramidTexture newTextureViewWithPixelFormat:MTLPixelFormatR32Float
                                                                  textureType:MTLTextureType2D
                                                                       levels:NSMakeRange(0, 1)
                                                                       slices:NSMakeRange(0, 1)];

        startMip = 1; // Skip first mip
    }
    for (uint i = startMip; i < pyramidTexture.mipmapLevelCount; i++)
    {
        id<MTLTexture> dstMip = [pyramidTexture newTextureViewWithPixelFormat:MTLPixelFormatR32Float
                                                                  textureType:MTLTextureType2D
                                                                       levels:NSMakeRange(i, 1)
                                                                       slices:NSMakeRange(0, 1)];
        dstMip.label = [NSString stringWithFormat:@"PyramidMipLevel%d" , i];

        [encoder setTexture:srcMip atIndex:0];
        [encoder setTexture:dstMip atIndex:1];

        simd::uint4 sizes = (simd::uint4) { (uint) srcMip.width, (uint) srcMip.height, 0, 0};
        [encoder setBytes:&sizes length:sizeof(simd::uint4) atIndex:AAPLBufferIndexDepthPyramidSize];

        [encoder dispatchThreadgroups:divideRoundUp({dstMip.width, dstMip.height, 1}, {8, 8, 1}) threadsPerThreadgroup:{8, 8, 1}];
        srcMip = dstMip;
    }

    [encoder popDebugGroup];
}

+ (bool) isPyramidTextureValidForDepth:(_Nullable id<MTLTexture>)pyramidTexture
                          depthTexture:(nonnull id<MTLTexture>)depthTexture
{
    bool validPyramid = (pyramidTexture != nil &&
                         pyramidTexture.width == depthTexture.width/2 &&
                         pyramidTexture.height == depthTexture.height/2);

    return validPyramid;
}

+ (nonnull id<MTLTexture>) allocatePyramidTextureFromDepth:(nonnull id<MTLTexture>)depthTexture
                                                    device:(nonnull id<MTLDevice>)device
{
    MTLTextureDescriptor* depthTexDesc =
    [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR32Float
                                                       width:depthTexture.width/2
                                                      height:depthTexture.height/2
                                                   mipmapped:true];

    if(depthTexture.textureType == MTLTextureType2DArray)
    {
        depthTexDesc.textureType  = MTLTextureType2DArray;
        depthTexDesc.arrayLength  = depthTexture.arrayLength;
    }

    depthTexDesc.storageMode    = MTLStorageModePrivate;
    depthTexDesc.usage          = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead | MTLTextureUsagePixelFormatView;

    return [device newTextureWithDescriptor:depthTexDesc];
}

@end
