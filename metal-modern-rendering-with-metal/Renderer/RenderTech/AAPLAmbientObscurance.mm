/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of class which manages state to render an scalable ambient obscurance (SAO) effect.
*/

#import "AAPLAmbientObscurance.h"
#import "AAPLDepthPyramid.h"
#import "AAPLCommon.h"
#import "AAPLShaderTypes.h"

#if USE_SCALABLE_AMBIENT_OBSCURANCE

@implementation AAPLAmbientObscurance
{
    // Device from initialization.
    id<MTLDevice>               _device;
    // Pipeline state for generating the SAO texture.
    id<MTLComputePipelineState> _scalableAmbientObscurancePipeline;
    // The underlying SAO texture.
    id<MTLTexture>              _texture;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device library:(id<MTLLibrary>)library
{
    self = [super init];
    if(self)
    {
        _device = device;

        _scalableAmbientObscurancePipeline = newComputePipelineState(library, @"scalableAmbientObscurance", @"ScalableAmbientObscurance", nil);
    }

    return self;
}

- (void)        update:(nonnull id<MTLCommandBuffer>)commandBuffer
       frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
    cameraParamsBuffer:(nonnull id<MTLBuffer>)cameraParamsBuffer
                 depth:(nonnull id<MTLTexture>)depth
          depthPyramid:(nonnull id<MTLTexture>)depthPyramid
{
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    computeEncoder.label = @"SAO Generation";

    [computeEncoder setComputePipelineState:_scalableAmbientObscurancePipeline];
    [computeEncoder setBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
    [computeEncoder setBuffer:cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];
    [computeEncoder setTexture:_texture atIndex:0];
    [computeEncoder setTexture:depth atIndex:1];
    [computeEncoder setTexture:depthPyramid atIndex:2];
    [computeEncoder dispatchThreads:MTLSizeMake(_texture.width, _texture.height, 1) threadsPerThreadgroup:MTLSizeMake(8, 8, 1)];
    [computeEncoder endEncoding];
}

- (void)resize:(CGSize)size
{
    bool validSAOTexture = (_texture != nil &&
                            _texture.width == size.width &&
                            _texture.height == size.height);
    if(!validSAOTexture)
    {
        MTLTextureDescriptor* saoTexDesc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm
                                                           width:size.width
                                                          height:size.height
                                                       mipmapped:false];
        saoTexDesc.storageMode  = MTLStorageModePrivate;
        saoTexDesc.usage        = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;

        _texture         = [_device newTextureWithDescriptor:saoTexDesc];
        _texture.label   = @"SAOTexture";
    }
}

@end

#endif // USE_SCALABLE_AMBIENT_OBSCURANCE
