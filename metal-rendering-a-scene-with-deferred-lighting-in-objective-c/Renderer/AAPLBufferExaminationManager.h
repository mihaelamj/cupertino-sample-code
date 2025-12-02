/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for renderer class which performs Metal setup and per frame rendering
*/
#import "AAPLConfig.h"

#if SUPPORT_BUFFER_EXAMINATION

@import MetalKit;

@class AAPLRenderer;

typedef enum AAPLExaminationMode
{
    AAPLExaminationModeDisabled           = 0x00,
    AAPLExaminationModeAlbedo             = 0x01,
    AAPLExaminationModeNormals            = 0x02,
    AAPLExaminationModeSpecular           = 0x04,
    AAPLExaminationModeDepth              = 0x08,
    AAPLExaminationModeShadowGBuffer      = 0x10,
    AAPLExaminationModeShadowMap          = 0x20,
    AAPLExaminationModeMaskedLightVolumes = 0x40,
    AAPLExaminationModeFullLightVolumes   = 0x80,
    AAPLExaminationModeAll                = 0xFF
} AAPLExaminationMode;

@interface AAPLBufferExaminationManager : NSObject

- (nonnull instancetype)initWithRenderer:(nonnull AAPLRenderer *)renderer
                       albedoGBufferView:(nonnull MTKView*)albedoGBufferView
                      normalsGBufferView:(nonnull MTKView*)normalsGBufferView
                        depthGBufferView:(nonnull MTKView*)depthGBufferView
                       shadowGBufferView:(nonnull MTKView*)shadowGBufferView
                          finalFrameView:(nonnull MTKView*)finalFrameView
                     specularGBufferView:(nonnull MTKView*)specularGBufferView
                           shadowMapView:(nonnull MTKView*)shadowMapView
                           lightMaskView:(nonnull MTKView*)lightMaskView
                       lightCoverageView:(nonnull MTKView*)lightCoverageView;

- (void)updateDrawableSize:(CGSize)size;

- (void)drawAndPresentBuffersWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer;

@property (nonatomic) AAPLExaminationMode mode;

// Texture for rendering the final scene when showing all buffers.  Rendered to in place of the
// drawable since all buffers will be rendered to the drawable
@property (nonatomic, nonnull, readonly) id<MTLTexture> offscreenDrawable;

@end

#endif // End SUPPORT_BUFFER_EXAMINATION

