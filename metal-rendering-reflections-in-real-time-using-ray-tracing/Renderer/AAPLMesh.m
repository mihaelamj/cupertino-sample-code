/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the mesh and submesh objects.
*/

@import MetalKit;
@import ModelIO;

#import "AAPLMesh.h"
#import "AAPLMathUtilities.h"
#import "AAPLArgumentBufferTypes.h"

@implementation AAPLSubmesh
{
    NSMutableArray<id<MTLTexture>> *_textures;
}

@synthesize textures = _textures;

/// Create a Metal texture with the given semantic in the given Model I/O material object.
+ (nonnull id<MTLTexture>) createMetalTextureFromMaterial:(nonnull MDLMaterial *)material
                                  modelIOMaterialSemantic:(MDLMaterialSemantic)materialSemantic
                                      modelIOMaterialType:(MDLMaterialPropertyType)defaultPropertyType
                                    metalKitTextureLoader:(nonnull MTKTextureLoader *)textureLoader
{
    id<MTLTexture> texture = nil;

    NSArray<MDLMaterialProperty *> *propertiesWithSemantic
        = [material propertiesWithSemantic:materialSemantic];

    for (MDLMaterialProperty *property in propertiesWithSemantic)
    {
        assert(property.semantic == materialSemantic);

        if(property.type != MDLMaterialPropertyTypeString)
        {
            continue;
        }

        // Load textures with TextureUsageShaderRead and StorageModePrivate.
        NSDictionary *textureLoaderOptions =
        @{
          MTKTextureLoaderOptionTextureUsage       : @(MTLTextureUsageShaderRead),
          MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
          };

        // Interpret the string as a file path and attempt to load it with
        //   ` -[MTKTextureLoader newTextureWithContentsOfURL:options:error:]`.

        NSURL *url = property.URLValue;
        NSMutableString *URLString = nil;
        if(property.type == MDLMaterialPropertyTypeURL) {
            URLString = [[NSMutableString alloc] initWithString:[url absoluteString]];
        } else {
            URLString = [[NSMutableString alloc] initWithString:@"file://"];
            [URLString appendString:property.stringValue];
        }

        NSURL *textureURL = [NSURL URLWithString:URLString];

        // Attempt to load the texture from the file system.
        texture = [textureLoader newTextureWithContentsOfURL:textureURL
                                                     options:textureLoaderOptions
                                                       error:nil];

        // If the texture loader finds a texture for a material using the string as a file path
        // name, return it.
        if(texture)
        {
            return texture;
        }

        // If the texture loader doesn't find a texture by interpreting the URL as a path,
        // interpret the string as an asset catalog name and attempt to load it with
        //  `-[MTKTextureLoader newTextureWithName:scaleFactor:bundle:options::error:]`.

        NSString *lastComponent =
            [[property.stringValue componentsSeparatedByString:@"/"] lastObject];

        texture = [textureLoader newTextureWithName:lastComponent
                                        scaleFactor:1.0
                                             bundle:nil
                                            options:textureLoaderOptions
                                              error:nil];

        // If Model I/O finds a texture by the interpreting the URL as an asset
        // catalog name, return it.
        if(texture) {
            return texture;
        }

        // If the texture loader doesn't find a texture by interpreting it as a file path or
        // as an asset name in the asset catalog, something is wrong. Perhaps the file is
        //  missing or misnamed in the asset catalog, model/material file, or file system.

        // Depending on the implementation of the Metal render pipeline with this submesh,
        // the system can handle this condition more gracefully.  The app can load a dummy
        // texture that looks OK when set with the pipeline, or ensure that the pipeline
        // rendering this submesh doesn't require a material with this property.

        [NSException raise:@"Texture data for material property not found"
                    format:@"Requested material property semantic: %lu string: %@",
                            materialSemantic, property.stringValue];
    }

    if (!texture)
    {
        [NSException raise:@"No appropriate material property from which to create texture"
                format:@"Requested material property semantic: %lu", materialSemantic];
    }

    return texture;
}

- (nonnull instancetype) initWithModelIOSubmesh:(nonnull MDLSubmesh *)modelIOSubmesh
                                metalKitSubmesh:(nonnull MTKSubmesh *)metalKitSubmesh
                          metalKitTextureLoader:(nonnull MTKTextureLoader *)textureLoader
{
    self = [super init];
    if(self)
    {
        _metalKitSubmesh = metalKitSubmesh;

        _textures = [[NSMutableArray alloc] initWithCapacity:AAPLMaterialTextureCount];

        // Fill up the texture array with null objects so that the renderer can index it.
        for(NSUInteger shaderIndex = 0; shaderIndex < AAPLMaterialTextureCount; shaderIndex++) {
            [_textures addObject:(id<MTLTexture>)[NSNull null]];
        }

        // Set each index in the array with the appropriate material semantic specified in the
        //   submesh's material property.

        _textures[AAPLTextureIndexBaseColor] =
            [AAPLSubmesh createMetalTextureFromMaterial:modelIOSubmesh.material
                                modelIOMaterialSemantic:MDLMaterialSemanticBaseColor
                                    modelIOMaterialType:MDLMaterialPropertyTypeFloat3
                                  metalKitTextureLoader:textureLoader];

        _textures[AAPLTextureIndexMetallic] =
            [AAPLSubmesh createMetalTextureFromMaterial:modelIOSubmesh.material
                                modelIOMaterialSemantic:MDLMaterialSemanticMetallic
                                    modelIOMaterialType:MDLMaterialPropertyTypeFloat3
                                  metalKitTextureLoader:textureLoader];

        _textures[AAPLTextureIndexRoughness] =
        [AAPLSubmesh createMetalTextureFromMaterial:modelIOSubmesh.material
                            modelIOMaterialSemantic:MDLMaterialSemanticRoughness
                                modelIOMaterialType:MDLMaterialPropertyTypeFloat3
                              metalKitTextureLoader:textureLoader];

        _textures[AAPLTextureIndexNormal] =
        [AAPLSubmesh createMetalTextureFromMaterial:modelIOSubmesh.material
                            modelIOMaterialSemantic:MDLMaterialSemanticTangentSpaceNormal
                                modelIOMaterialType:MDLMaterialPropertyTypeNone
                              metalKitTextureLoader:textureLoader];

        _textures[AAPLTextureIndexAmbientOcclusion] =
            [AAPLSubmesh createMetalTextureFromMaterial:modelIOSubmesh.material
                                modelIOMaterialSemantic:MDLMaterialSemanticAmbientOcclusion
                                    modelIOMaterialType:MDLMaterialPropertyTypeNone
                                  metalKitTextureLoader:textureLoader];
    }
    return self;
}

@end

@implementation AAPLMesh
{
    NSMutableArray<AAPLSubmesh *> *_submeshes;
}

- (NSArray<AAPLSubmesh*> *)submeshes
{
    return _submeshes;
}

- (void)setSubmeshes:(NSArray<AAPLSubmesh *> *)submeshes
{
    _submeshes = [submeshes mutableCopy];
}

/// Load the Model I/O mesh, including vertex data and submesh data that have index buffers and
///   textures.  Also generate tangent and bitangent vertex attributes.
- (nonnull instancetype) initWithModelIOMesh:(nonnull MDLMesh *)modelIOMesh
                     modelIOVertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor
                       metalKitTextureLoader:(nonnull MTKTextureLoader *)textureLoader
                                 metalDevice:(nonnull id<MTLDevice>)device
                                       error:(NSError * __nullable * __nullable)error
{
    self = [super init];
    if(!self) {
        return nil;
    }

    [modelIOMesh addNormalsWithAttributeNamed:MDLVertexAttributeNormal
                       creaseThreshold:0.98];

    // Have Model I/O create the tangents from the mesh texture coordinates and normals.
    [modelIOMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                              normalAttributeNamed:MDLVertexAttributeNormal
                                             tangentAttributeNamed:MDLVertexAttributeTangent];

    // Have Model I/O create bitangents from the mesh texture coordinates and the newly created tangents.
    [modelIOMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                             tangentAttributeNamed:MDLVertexAttributeTangent
                                           bitangentAttributeNamed:MDLVertexAttributeBitangent];

    // Assigning a new vertex descriptor to a Model I/O mesh performs a relayout of the vertex
    // data.  In this case, the renderer creates the Model I/O vertex descriptor so that the
    // layout of the vertices in the ModelIO mesh match the layout of vertices that that Metal render
    // pipeline expects as input into its vertex shader.

    // Note: Model I/O must create tangents and bitangents (as done above) before this
    // relayout occurs.
    // Model I/O's `addTangentBasis` methods only work with vertex data that is all
    // in 32-bit floating-point. Applying the vertex descriptor changes those floats
    // into 16-bit float-point or other types from which Model I/O can't produce tangents.

    modelIOMesh.vertexDescriptor = vertexDescriptor;

    // Create the MetalKit mesh, which contains the Metal buffers with the mesh's vertex data
    //   and submeshes with data to draw the mesh.
    MTKMesh* metalKitMesh = [[MTKMesh alloc] initWithMesh:modelIOMesh
                                                   device:device
                                                    error:error];

    _metalKitMesh = metalKitMesh;

    // A MetalKit mesh needs to always have the same number of MetalKit submeshes
    // as the Model I/O mesh has submeshes.
    assert(metalKitMesh.submeshes.count == modelIOMesh.submeshes.count);

    // Create an array to hold this `AAPLMesh` object's `AAPLSubmesh` objects.
    _submeshes = [[NSMutableArray alloc] initWithCapacity:metalKitMesh.submeshes.count];

    // Create an `AAPLSubmesh` object for each submesh and add it to the submesh's array.
    for(NSUInteger index = 0; index < metalKitMesh.submeshes.count; index++)
    {
        // Create an app-specific submesh to hold the MetalKit submesh.
        AAPLSubmesh *submesh =
            [[AAPLSubmesh alloc] initWithModelIOSubmesh:modelIOMesh.submeshes[index]
                                        metalKitSubmesh:metalKitMesh.submeshes[index]
                                  metalKitTextureLoader:textureLoader]; 

        [_submeshes addObject:submesh];
    }

    return self;
}

/// Traverses the Model I/O object hierarchy that picks out Model I/O mesh objects and creates Metal
///   vertex buffers, index buffers, and textures.
+ (NSArray<AAPLMesh*> *) newMeshesFromObject:(nonnull MDLObject*)object
                     modelIOVertexDescriptor:(nonnull MDLVertexDescriptor*)vertexDescriptor
                       metalKitTextureLoader:(nonnull MTKTextureLoader *)textureLoader
                                 metalDevice:(nonnull id<MTLDevice>)device
                                       error:(NSError * __nullable * __nullable)error {

    NSMutableArray<AAPLMesh *> *newMeshes = [[NSMutableArray alloc] init];

    // If this Model I/O object is a mesh object (not a camera, light, or something else),
    // create an app-specific `AAPLMesh` object from it.
    if ([object isKindOfClass:[MDLMesh class]])
    {
        MDLMesh* mesh = (MDLMesh*) object;

        AAPLMesh *newMesh = [[AAPLMesh alloc] initWithModelIOMesh:mesh
                                          modelIOVertexDescriptor:vertexDescriptor
                                            metalKitTextureLoader:textureLoader
                                                      metalDevice:device
                                                            error:error];

        [newMeshes addObject:newMesh];
    }

    // Recursively traverse the Model I/O asset hierarchy to find nodes that are
    // Model I/O meshes and create app-specific `AAPLMesh` objects from those meshes.
    for (MDLObject *child in object.children)
    {
        NSArray<AAPLMesh*> *childMeshes;

        childMeshes = [AAPLMesh newMeshesFromObject:child
                            modelIOVertexDescriptor:vertexDescriptor
                              metalKitTextureLoader:textureLoader
                                        metalDevice:device
                                              error:error];

        [newMeshes addObjectsFromArray:childMeshes];
    }

    return newMeshes;
}

/// Uses Model I/O to load a model file at the given URL, create Model I/O vertex buffers,  index buffers,
///   and textures, applying the given Model I/O vertex descriptor to lay out vertex attribute data
///   in the way that the Metal vertex shaders expect.
+ (nullable NSArray<AAPLMesh *> *) newMeshesFromURL:(nonnull NSURL *)url
                            modelIOVertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor
                                        metalDevice:(nonnull id<MTLDevice>)device
                                              error:(NSError * __nullable * __nullable)error
{

    // Create a MetalKit mesh buffer allocator so that Model I/O loads mesh data directly into
    //   Metal buffers accessible by the GPU.
    MTKMeshBufferAllocator *bufferAllocator =
        [[MTKMeshBufferAllocator alloc] initWithDevice:device];

    // Use ModelIO to load the model file at the URL.  This returns a Model I/O asset
    // object, which contains a hierarchy of ModelIO objects composing a "scene" that
    // the model file describes.  This hierarchy may include lights and cameras, but,
    // most importantly, mesh and submesh data that Metal renders.
    MDLAsset *asset = [[MDLAsset alloc] initWithURL:url
                                   vertexDescriptor:nil
                                    bufferAllocator:bufferAllocator];

    NSAssert(asset, @"Failed to open model file with given URL: %@", url.absoluteString);

    // Create a MetalKit texture loader to load material textures from files or the asset catalog
    //   into Metal textures.
    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];

    NSMutableArray<AAPLMesh *> *newMeshes = [[NSMutableArray alloc] init];

    // Traverse the Model I/O asset hierarchy to find Model I/O meshes and create app-specific
    //   AAPLMesh objects from those Model I/O meshes.
    for(MDLObject* object in asset)
    {
        NSArray<AAPLMesh *> *assetMeshes;

        assetMeshes = [AAPLMesh newMeshesFromObject:object
                            modelIOVertexDescriptor:vertexDescriptor
                              metalKitTextureLoader:textureLoader
                                        metalDevice:device
                                              error:error];

        [newMeshes addObjectsFromArray:assetMeshes];
    }

    return newMeshes;
}

+ (nullable AAPLMesh *)newSkyboxMeshOnDevice:(id< MTLDevice >)device vertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor
{
    MTKMeshBufferAllocator* bufferAllocator = [[MTKMeshBufferAllocator alloc] initWithDevice:device];

    MDLMesh* mdlMesh = [MDLMesh newEllipsoidWithRadii:(vector_float3){200, 200, 200}
                                       radialSegments:10
                                     verticalSegments:10
                                         geometryType:MDLGeometryTypeTriangles
                                        inwardNormals:YES
                                           hemisphere:NO
                                            allocator:bufferAllocator];

    mdlMesh.vertexDescriptor = vertexDescriptor;

    NSError* __autoreleasing error = nil;
    MTKMesh* mtkMesh = [[MTKMesh alloc] initWithMesh:mdlMesh
                                              device:device
                                               error:&error];

    NSAssert(mtkMesh, @"Error creating skybox mesh: %@", error);

    return [[AAPLMesh alloc] initWithMtkMesh:mtkMesh];

}

+ (nullable AAPLMesh *)newMesh:(nonnull MDLMesh *)modelIOMesh material:(nonnull MDLMaterial *)material onDevice:(id< MTLDevice >)device vertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor
{
    NSError* __autoreleasing error = nil;
    
    // Assigning a new vertex descriptor to a Model I/O mesh performs a relayout of
    // the vertex data.
    modelIOMesh.vertexDescriptor = vertexDescriptor;

    // Create the MetalKit mesh that contains the Metal buffers with the mesh's
    // vertex data and submeshes with data to draw the mesh.
    MTKMesh* metalKitMesh = [[MTKMesh alloc] initWithMesh:modelIOMesh
                                                   device:device
                                                    error:&error];

    NSAssert(metalKitMesh, @"Error creating sphere: %@", error);
    
    AAPLMesh* mesh = [[AAPLMesh alloc] initWithMtkMesh:metalKitMesh];
    
    MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
    
    NSMutableArray< AAPLSubmesh* >* submeshes = [[NSMutableArray alloc] init];
    for ( int i = 0; i < metalKitMesh.submeshes.count; ++i )
    {
        modelIOMesh.submeshes[i].material = material;
        AAPLSubmesh* submesh = [[AAPLSubmesh alloc] initWithModelIOSubmesh:modelIOMesh.submeshes[i]
                                                           metalKitSubmesh:metalKitMesh.submeshes[i]
                                                     metalKitTextureLoader:textureLoader];
        NSAssert( submesh, @"Error allocating submesh" );
        [submeshes addObject:submesh];
    }
    
    mesh.submeshes = submeshes;
    
    return mesh;
}

+ (nullable AAPLMesh *)newSphereWithRadius:(float)radius onDevice:(nonnull id< MTLDevice >)device vertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor
{
    MTKMeshBufferAllocator* bufferAllocator  = [[MTKMeshBufferAllocator alloc] initWithDevice:device];
    
    MDLMesh* modelIOMesh = [MDLMesh newEllipsoidWithRadii:(vector_float3){radius, radius, radius}
                                       radialSegments:20
                                     verticalSegments:20
                                         geometryType:MDLGeometryTypeTriangles
                                        inwardNormals:NO
                                           hemisphere:NO
                                            allocator:bufferAllocator];
    
    // Model I/O creates the tangents from the mesh's texture coordinates and normals.
    [modelIOMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                              normalAttributeNamed:MDLVertexAttributeNormal
                                             tangentAttributeNamed:MDLVertexAttributeTangent];

    // Model I/O creates bitangents from the mesh's texture coordinates and
    // the newly created tangents.
    [modelIOMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                             tangentAttributeNamed:MDLVertexAttributeTangent
                                           bitangentAttributeNamed:MDLVertexAttributeBitangent];
    
    modelIOMesh.vertexDescriptor = vertexDescriptor;
    
    MDLMaterial* material = [[MDLMaterial alloc] init];
    
    // The texture strings that reference the contents of `Assets.xcassets` file.
    [material setProperty:[[MDLMaterialProperty alloc] initWithName:@"baseColor"
                                                           semantic:MDLMaterialSemanticBaseColor
                                                             string:@"white"]];
    
    [material setProperty:[[MDLMaterialProperty alloc] initWithName:@"metallic"
                                                           semantic:MDLMaterialSemanticMetallic
                                                             string:@"white"]];
    
    [material setProperty:[[MDLMaterialProperty alloc] initWithName:@"roughness"
                                                           semantic:MDLMaterialSemanticRoughness
                                                             string:@"black"]];
    
    [material setProperty:[[MDLMaterialProperty alloc] initWithName:@"tangentNormal"
                                                           semantic:MDLMaterialSemanticTangentSpaceNormal
                                                             string:@"BodyNormalMap"]];
    
    [material setProperty:[[MDLMaterialProperty alloc] initWithName:@"ao"
                                                           semantic:MDLMaterialSemanticAmbientOcclusion
                                                             string:@"white"]];
    
    return [AAPLMesh newMesh:modelIOMesh
                    material:material
                    onDevice:device
            vertexDescriptor:vertexDescriptor];
}

+ (nullable AAPLMesh *)newPlaneWithDimensions:(vector_float2)dimensions onDevice:(nonnull id< MTLDevice >)device vertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor
{
    MTKMeshBufferAllocator* bufferAllocator  = [[MTKMeshBufferAllocator alloc] initWithDevice:device];
    
    MDLMesh* modelIOMesh = [MDLMesh newPlaneWithDimensions:dimensions
                                                  segments:(vector_uint2){100u, 100u}
                                              geometryType:MDLGeometryTypeTriangles
                                                 allocator:bufferAllocator];
    
    // Model I/O creates the tangents from the mesh's texture coordinates and normals.
    [modelIOMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                              normalAttributeNamed:MDLVertexAttributeNormal
                                             tangentAttributeNamed:MDLVertexAttributeTangent];

    // Model I/O creates bitangents from the mesh's texture coordinates and the
    // newly created tangents.
    [modelIOMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                             tangentAttributeNamed:MDLVertexAttributeTangent
                                           bitangentAttributeNamed:MDLVertexAttributeBitangent];
    
    modelIOMesh.vertexDescriptor = vertexDescriptor;
    
    {
        // Repeat the floor texture coordinates 20 times over.
        const float kFloorRepeat = 20.0f;
        MDLVertexAttributeData* texcoords = [modelIOMesh vertexAttributeDataForAttributeNamed:MDLVertexAttributeTextureCoordinate];
        NSAssert( texcoords, @"Mesh contains no texture coordinate data" );
        MDLMeshBufferMap* map = texcoords.map;
        vector_float2* uv = (vector_float2 *)map.bytes;
        for ( NSUInteger i = 0; i < texcoords.bufferSize / sizeof(vector_float2); ++i )
        {
            uv[i].x *= kFloorRepeat;
            uv[i].y *= kFloorRepeat;
        }
    }
    
    
    MDLMaterial* material = [[MDLMaterial alloc] init];
    
    // The texture strings that reference the contents of the `Assets.xcassets` file.
    [material setProperty:[[MDLMaterialProperty alloc] initWithName:@"baseColor"
                                                           semantic:MDLMaterialSemanticBaseColor
                                                             string:@"checkerboard_gray"]];
    
    [material setProperty:[[MDLMaterialProperty alloc] initWithName:@"metallic"
                                                           semantic:MDLMaterialSemanticMetallic
                                                             string:@"white"]];
    
    [material setProperty:[[MDLMaterialProperty alloc] initWithName:@"roughness"
                                                           semantic:MDLMaterialSemanticRoughness
                                                             string:@"black"]];
    
    [material setProperty:[[MDLMaterialProperty alloc] initWithName:@"tangentNormal"
                                                           semantic:MDLMaterialSemanticTangentSpaceNormal
                                                             string:@"BodyNormalMap"]];
    
    [material setProperty:[[MDLMaterialProperty alloc] initWithName:@"ao"
                                                           semantic:MDLMaterialSemanticAmbientOcclusion
                                                             string:@"white"]];
    
    return [AAPLMesh newMesh:modelIOMesh
                    material:material
                    onDevice:device
            vertexDescriptor:vertexDescriptor];
}

- (instancetype)initWithMtkMesh:(MTKMesh *)mtkMesh
{
    if ( self = [super init] )
    {
        _metalKitMesh = mtkMesh;
    }
    return self;
}

@end

#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>

static CGImageRef createCGImageFromFile (NSString* path)
{
    // Get the URL for the pathname to pass it to
    // `CGImageSourceCreateWithURL`.
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageRef        myImage = NULL;
    CGImageSourceRef  myImageSource;
    CFDictionaryRef   myOptions = NULL;
    CFStringRef       myKeys[2];
    CFTypeRef         myValues[2];

    // Set up options if you want them. The options here are for
    // caching the image in a decoded form and for using floating-point
    // values if the image format supports them.
    myKeys[0] = kCGImageSourceShouldCache;
    myValues[0] = (CFTypeRef)kCFBooleanFalse;

    myKeys[1] = kCGImageSourceShouldAllowFloat;
    myValues[1] = (CFTypeRef)kCFBooleanTrue;

    // Create the dictionary.
    myOptions = CFDictionaryCreate(NULL,
                                   (const void **) myKeys,
                                   (const void **) myValues, 2,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   & kCFTypeDictionaryValueCallBacks);

    // Create an image source from the URL.
    myImageSource = CGImageSourceCreateWithURL((CFURLRef)url, myOptions);
    CFRelease(myOptions);

    // Make sure the image source exists before continuing.
    if (myImageSource == NULL)
    {
        fprintf(stderr, "Image source is NULL.");
        return  NULL;
    }

    // Create an image from the first item in the image source.
    myImage = CGImageSourceCreateImageAtIndex(myImageSource, 0, NULL);
    CFRelease(myImageSource);

    // Make sure the image exists before continuing.
    if (myImage == NULL)
    {
         fprintf(stderr, "Image not created from image source.");
         return NULL;
    }

    return myImage;
}

id<MTLTexture> texture_from_radiance_file(NSString * fileName, id<MTLDevice> device, NSError ** error)
{
    // Validate the function inputs.

    if (![fileName containsString:@"."])
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"File load failure."
                                                code:0xdeadbeef
                                            userInfo:@{NSLocalizedDescriptionKey : @"No file extension provided."}];
        }
        return nil;
    }

    NSArray * subStrings = [fileName componentsSeparatedByString:@"."];

    if ([subStrings[1] compare:@"hdr"] != NSOrderedSame)
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"File load failure."
                                                code:0xdeadbeef
                                            userInfo:@{NSLocalizedDescriptionKey : @"Only (.hdr) files are supported."}];
        }
        return nil;
    }

    // Load and validate the image.

    NSString* filePath = [[NSBundle mainBundle] pathForResource:subStrings[0] ofType:subStrings[1]];
    CGImageRef loadedImage = createCGImageFromFile(filePath);

    if (loadedImage == NULL)
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"File load failure."
                                                code:0xdeadbeef
                                            userInfo:@{NSLocalizedDescriptionKey : @"Unable to create CGImage."}];
        }

        return nil;
    }

    size_t bpp = CGImageGetBitsPerPixel(loadedImage);

    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(loadedImage);
    const size_t kSrcChannelCount = (kCGImageAlphaNone == alphaInfo) ? 3 : 4;
    const size_t kBitsPerByte = 8;
    const size_t kExpectedBitsPerPixel = sizeof(uint16_t) * kSrcChannelCount * kBitsPerByte;

    if (bpp != kExpectedBitsPerPixel)
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"File load failure."
                                                code:0xdeadbeef
                                            userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Expected %zu bits per pixel, but file returns %zu", kExpectedBitsPerPixel, bpp]}];
        }
        CFRelease(loadedImage);
        return nil;
    }

    // Copy the image into a tempory buffer.

    size_t width = CGImageGetWidth(loadedImage);
    size_t height = CGImageGetHeight(loadedImage);

    // Make the CG image data accessible.
    CFDataRef cgImageData = CGDataProviderCopyData(CGImageGetDataProvider(loadedImage));

    // Get a pointer to the data.
    const uint16_t * srcData = (const uint16_t * )CFDataGetBytePtr(cgImageData);

    uint16_t * paddedData = nil;
    const size_t kDstChannelCount = 4;

    if (3 == kSrcChannelCount)
    {
        // Pads the data with an extra channel (byte) because the source data is RGB16F,
        // but Metal exposes it as an RGBA16Float format.
        const size_t kPixelCount = width * height;
        const size_t kDstSize = kPixelCount * sizeof(uint16_t) * kDstChannelCount;
        
        paddedData = (uint16_t *)malloc(kDstSize);
        
        for (size_t texIdx = 0; texIdx < kPixelCount; ++texIdx)
        {
            const uint16_t * currSrc = srcData + (texIdx * kSrcChannelCount);
            uint16_t * currDst = paddedData + (texIdx * kDstChannelCount);
            
            currDst[0] = currSrc[0];
            currDst[1] = currSrc[1];
            currDst[2] = currSrc[2];
            currDst[3] = float16_from_float32(1.f);
        }
    }

    // Create an `MTLTexture`.

    MTLTextureDescriptor * texDesc = [MTLTextureDescriptor new];

    texDesc.pixelFormat = MTLPixelFormatRGBA16Float;
    texDesc.width = width;
    texDesc.height = height;

    id<MTLTexture> texture = [device newTextureWithDescriptor:texDesc];

    const NSUInteger kBytesPerRow = sizeof(uint16_t) * kDstChannelCount * width;

    MTLRegion region = { {0,0,0}, {width, height, 1} };

    [texture replaceRegion:region mipmapLevel:0 withBytes:paddedData ? paddedData : srcData bytesPerRow:kBytesPerRow];

    // Remember to clean things up.
    if (paddedData)
        free(paddedData);
    CFRelease(cgImageData);
    CFRelease(loadedImage);

    return texture;
}
