/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for renderer class which performs Metal setup and per frame rendering
*/
#import "AAPLConfig.h"
#import "AAPLBufferExaminationManager.h"

@import MetalKit;

// Number of "fairy" lights in scene
static const NSUInteger AAPLNumLights = 256;

static const float AAPLNearPlane = 1;
static const float AAPLFarPlane = 150;

@interface AAPLRenderer : NSObject

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

// Common rendering methods called by derived classes

- (void)loadMetal;

- (void)loadScene;

- (void)drawSceneToView:(nonnull MTKView *)view;

- (nonnull id <MTLCommandBuffer>)beginFrame;

- (nonnull id <MTLCommandBuffer>)beginDrawableCommands;

- (void)endFrame:(nonnull id <MTLCommandBuffer>)commandBuffer;

- (void)drawMeshes:(nonnull id<MTLRenderCommandEncoder>)renderEncoder;

- (void)drawShadow:(nonnull id <MTLCommandBuffer>)commandBuffer;

- (void)drawGBuffer:(nonnull id <MTLRenderCommandEncoder>)renderEncoder;

- (void)drawDirectionalLightCommon:(nonnull id <MTLRenderCommandEncoder>)renderEncoder;

- (void)drawPointLightMask:(nonnull id<MTLRenderCommandEncoder>)renderEncoder;

- (void)drawPointLightsCommon:(nonnull id<MTLRenderCommandEncoder>)renderEncoder;

- (void)drawFairies:(nonnull id <MTLRenderCommandEncoder>)renderEncoder;

- (void)drawSky:(nonnull id <MTLRenderCommandEncoder>)renderEncoder;

- (void)drawableSizeWillChange:(CGSize)size withGBufferStorageMode:(MTLStorageMode)storageMode;

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size;

@property (nonatomic, readonly, nonnull) id <MTLDevice> device;

@property (nonatomic, readonly, nullable, weak) MTKView *view;

// Current buffer to fill with dynamic franme data data and set for the current frame
@property (nonatomic, readonly) int8_t frameDataBufferIndex;

// GBuffer properties

@property (nonatomic, readonly) MTLPixelFormat albedo_specular_GBufferFormat;

@property (nonatomic, readonly) MTLPixelFormat normal_shadow_GBufferFormat;

@property (nonatomic, readonly) MTLPixelFormat depth_GBufferFormat;

@property (nonatomic, readonly, nonnull) id <MTLTexture> albedo_specular_GBuffer;

@property (nonatomic, readonly, nonnull) id <MTLTexture> normal_shadow_GBuffer;

@property (nonatomic, readonly, nonnull) id <MTLTexture> depth_GBuffer;

@property (nonatomic, readonly, nullable) id <MTLTexture> depthStencilTexture;

@property (nonatomic, readonly, nullable) id <MTLTexture> currentDrawableTexture;

// Depth texture used to render shadows
@property (nonatomic, readonly, nonnull) id <MTLTexture> shadowMap;

// This is used to build render pipelines that perform common operations for both traditional and
// singlePass deferred renderers.  The only difference between these versions of these pipelines
// is that the single pass renderer needs the GBuffers attached as render targets while the
// traditional renderer needs the GBuffers set as textures to sample/read from.   So this is YES for
// the single pass renderer and NO for the traditional renderer.  This enables more sharing of the
// Between the two renderer in base class which is common to both renderers.
@property (nonatomic) BOOL singlePassDeferred;

@property (nonatomic, readonly, nonnull) id <MTLDepthStencilState> dontWriteDepthStencilState;

@property (nonatomic, readonly, nonnull) id <MTLDepthStencilState> pointLightDepthStencilState;

// Buffers used to store dynamically changing per frame data
@property (nonatomic, readonly, nonnull) NSArray<id<MTLBuffer>> *frameDataBuffers;

// Buffers used to story dynamically changing light positions
@property (nonatomic, readonly, nonnull) NSArray<id<MTLBuffer>> *lightPositions;

// Buffer for constant light data
@property (nonatomic, readonly, nonnull) id <MTLBuffer> lightsData;

// Mesh for an icosahedron used for rendering point lights
@property (nonatomic, readonly, nonnull) MTKMesh *icosahedronMesh;

// Mesh buffer for simple Quad
@property (nonatomic, readonly, nonnull)  id<MTLBuffer> quadVertexBuffer;

// Pixel format used for final frame's color target
@property (nonatomic, readonly) MTLPixelFormat colorTargetPixelFormat;

// Pixel format used for final frame's depth target
@property (nonatomic, readonly) MTLPixelFormat depthStencilTargetPixelFormat;

@property (nonatomic, nonnull, readonly) id<MTLLibrary> shaderLibrary;

#if SUPPORT_BUFFER_EXAMINATION

- (void)validateBufferExaminationMode;

@property (nonatomic, weak, nullable) AAPLBufferExaminationManager *bufferExaminationManager;

#endif

@end
