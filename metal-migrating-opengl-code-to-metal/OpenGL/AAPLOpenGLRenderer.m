/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the renderer class that performs OpenGL state setup and per-frame rendering.
*/

#import "AAPLOpenGLRenderer.h"
#import "AAPLMathUtilities.h"
#import "AAPLMeshData.h"
#import "AAPLCommonDefinitions.h"
#import <Foundation/Foundation.h>
#import <simd/simd.h>

@implementation AAPLOpenGLRenderer
{
    GLuint _defaultFBOName;
    CGSize _viewSize;

    GLint _mvpUniformIndex;
    GLint _uniformBufferIndex;

    matrix_float4x4 _projectionMatrix;
    // Open GL Objects you use to render the temple mesh.
    GLuint _templeVAO;
    GLuint _templeVertexPositions;
    GLuint _templeVertexGenerics;
    GLuint _templeProgram;
    GLuint _templeMVPUniformLocation;
    matrix_float4x4 _templeCameraMVPMatrix;

    // Arrays of submesh index buffers and textures for temple mesh.
    NSUInteger _numTempleSubmeshes;
    GLuint *_templeIndexBufferCounts;
    GLuint *_templeIndexBuffers;
    GLuint *_templeTextures;

#if RENDER_REFLECTION
    GLuint _reflectionFBO;
    GLuint _reflectionColorTexture;
    GLuint _reflectionDepthBuffer;
    GLuint _reflectionQuadBuffer;
    GLuint _reflectionQuadVAO;
    GLuint _reflectionProgram;
    GLuint _reflectionQuadMVPUniformLocation;

    matrix_float4x4 _reflectionQuadMVPMatrix;
    matrix_float4x4 _templeReflectionMVPMatrix;
#endif


#if USE_UNIFORM_BLOCKS
    // Uniform buffer instance variables.
    GLuint _uniformBlockIndex;
    GLuint _uniformBlockBuffer;
    GLint *_uniformBlockOffsets;
    GLubyte *_uniformBlockData;
    GLsizei _uniformBlockSize;
#else
    GLuint _templeNormalMatrixUniformLocation;
    GLuint _ambientLightColorUniformLocation;
    GLuint _directionalLightInvDirectionUniformLocation;
    GLuint _directionalLightColorUniformLocation;

    matrix_float3x3 _templeNormalMatrix;
    vector_float3 _ambientLightColor;
    vector_float3 _directionalLightInvDirection;
    vector_float3 _directionalLightColor;
#endif


    float _rotation;
}

- (instancetype)initWithDefaultFBOName:(GLuint)defaultFBOName
{
    self = [super init];
    if(self)
    {
        NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));

        // Build all of your objects and setup initial state here.
        _defaultFBOName = defaultFBOName;

        [self buildTempleObjects];

        [self buildReflectiveQuadObjects];
    }

    return self;
}

- (void) dealloc
{
    glDeleteProgram(_reflectionProgram);
    glDeleteProgram(_templeProgram);

    glDeleteVertexArrays(1, &_templeVAO);
    glDeleteVertexArrays(1, &_reflectionQuadVAO);

    glDeleteBuffers(1, &_templeVertexPositions);
    glDeleteBuffers(1, &_templeVertexGenerics);
    glDeleteBuffers(1, &_reflectionQuadBuffer);

    glDeleteTextures(1, &_reflectionColorTexture);
    glDeleteRenderbuffers(1, &_reflectionDepthBuffer);

    glDeleteFramebuffers(1, &_reflectionFBO);

    for(int i = 0; i < _numTempleSubmeshes; i++)
    {
        glDeleteTextures(1, &_templeTextures[i]);
        glDeleteBuffers(1, &_templeIndexBuffers[i]);
    }

    free(_templeIndexBufferCounts);
    free(_templeIndexBuffers);
    free(_templeTextures);
}

- (void) buildTempleObjects
{
    // Load the mesh data from a file.
    NSError *error;

    NSURL *modelFileURL = [[NSBundle mainBundle] URLForResource:@"Meshes/Temple.obj"
                                                  withExtension:nil];

    NSAssert(modelFileURL, @"Could not find model (%@) file in the bundle.", modelFileURL.absoluteString);

    // Load mesh data from a file into memory.
    // This only loads data from the bundle and does not create any OpenGL objects.

    AAPLMeshData *meshData = [[AAPLMeshData alloc] initWithURL:modelFileURL error:&error];

    NSAssert(meshData, @"Could not load mesh from model file (%@), error: %@.", modelFileURL.absoluteString, error);

    // Extract the vertex data, reconfigure the layout for the vertex shader, and place the data into
    // an OpenGL vertex buffer.
    {
        NSUInteger positionElementSize = sizeof(vector_float3);
        NSUInteger positionDataSize    = positionElementSize * meshData.vertexCount;

        NSUInteger genericElementSize = sizeof(AAPLVertexGenericData);
        NSUInteger genericsDataSize   = genericElementSize * meshData.vertexCount;

        vector_float3         *positionsArray = (vector_float3 *)malloc(positionDataSize);
        AAPLVertexGenericData *genericsArray = (AAPLVertexGenericData *)malloc(genericsDataSize);

        // Extract vertex data from the buffer and lay it out for OpenGL buffers.
        struct AAPLVertexData *vertexData = meshData.vertexData;

        for(unsigned long vertex = 0; vertex < meshData.vertexCount; vertex++)
        {
            positionsArray[vertex] = vertexData[vertex].position;
            genericsArray[vertex].texcoord = vertexData[vertex].texcoord;
            genericsArray[vertex].normal.x = vertexData[vertex].normal.x;
            genericsArray[vertex].normal.y = vertexData[vertex].normal.y;
            genericsArray[vertex].normal.z = vertexData[vertex].normal.z;
        }

        // Place formatted vertex data into OpenGL buffers.
        glGenBuffers(1, &_templeVertexPositions);

        glBindBuffer(GL_ARRAY_BUFFER, _templeVertexPositions);

        glBufferData(GL_ARRAY_BUFFER, positionDataSize, positionsArray, GL_STATIC_DRAW);

        glGenBuffers(1, &_templeVertexGenerics);

        glBindBuffer(GL_ARRAY_BUFFER, _templeVertexGenerics);

        glBufferData(GL_ARRAY_BUFFER, genericsDataSize, genericsArray, GL_STATIC_DRAW);

        glGenVertexArrays(1, &_templeVAO);

        glBindVertexArray(_templeVAO);

        // Setup buffer with positions.
        glBindBuffer(GL_ARRAY_BUFFER, _templeVertexPositions);
        glVertexAttribPointer(AAPLVertexAttributePosition, 3, GL_FLOAT, GL_FALSE, sizeof(vector_float3), BUFFER_OFFSET(0));
        glEnableVertexAttribArray(AAPLVertexAttributePosition);

        // Setup buffer with normals and texture coordinates.
        glBindBuffer(GL_ARRAY_BUFFER, _templeVertexGenerics);

        glVertexAttribPointer(AAPLVertexAttributeTexcoord, 2, GL_FLOAT, GL_FALSE, sizeof(AAPLVertexGenericData), BUFFER_OFFSET(0));
        glEnableVertexAttribArray(AAPLVertexAttributeTexcoord);

        glVertexAttribPointer(AAPLVertexAttributeNormal, 3, GL_FLOAT, GL_FALSE, sizeof(AAPLVertexGenericData), BUFFER_OFFSET(sizeof(vector_float2)));
        glEnableVertexAttribArray(AAPLVertexAttributeNormal);
    }

    // Load submesh data into index buffers and textures.
    {
        _numTempleSubmeshes = (NSUInteger)meshData.submeshes.allValues.count;
        _templeIndexBuffers = (GLuint*)malloc(sizeof(GLuint*) * _numTempleSubmeshes);
        _templeIndexBufferCounts = (GLuint*)malloc(sizeof(GLuint*) * _numTempleSubmeshes);
        _templeTextures = (GLuint*)malloc(sizeof(GLuint*) * _numTempleSubmeshes);

        NSDictionary *loaderOptions =
        @{
          GLKTextureLoaderGenerateMipmaps : @YES,
          GLKTextureLoaderOriginBottomLeft : @YES,
          };

        for(NSUInteger index = 0; index < _numTempleSubmeshes; index++)
        {
            AAPLSubmeshData *submeshData = meshData.submeshes.allValues[index];

            _templeIndexBufferCounts[index] = (GLuint)submeshData.indexCount;

            NSUInteger indexBufferSize = sizeof(uint32_t) * submeshData.indexCount;

            GLuint indexBufferName;

            glGenBuffers(1, &indexBufferName);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferName);

            glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexBufferSize, submeshData.indexData, GL_STATIC_DRAW);

            _templeIndexBuffers[index] = indexBufferName;

            GLKTextureInfo *texInfo = [GLKTextureLoader textureWithContentsOfURL:submeshData.baseColorMapURL
                                                                         options:loaderOptions
                                                                           error:&error];

            NSAssert(texInfo, @"Could not load image (%@) into OpenGL texture, error: %@.",
                     submeshData.baseColorMapURL.absoluteString, error);

            _templeTextures[index] = texInfo.name;
        }
    }

    // Create program object and setup for uniforms.
    {
        NSURL *vertexSourceURL = [[NSBundle mainBundle] URLForResource:@"temple" withExtension:@"vsh"];
        NSURL *fragmentSourceURL = [[NSBundle mainBundle] URLForResource:@"temple" withExtension:@"fsh"];

        _templeProgram = [AAPLOpenGLRenderer buildProgramWithVertexSourceURL:vertexSourceURL
                                                       withFragmentSourceURL:fragmentSourceURL
                                                                  hasNormals:YES];

        _templeMVPUniformLocation = glGetUniformLocation(_templeProgram, "modelViewProjectionMatrix");

        GLint location = -1;
        location = glGetUniformLocation(_templeProgram, "templeNormalMatrix");
        NSAssert(location >= 0, @"No location for `templeNormalMatrix`.");
        _templeNormalMatrixUniformLocation = (GLuint)location;


        location = glGetUniformLocation(_templeProgram, "ambientLightColor");
        NSAssert(location >= 0, @"No location for `ambientLightColor`.");
        _ambientLightColorUniformLocation = (GLuint)location;

        location = glGetUniformLocation(_templeProgram, "directionalLightInvDirection");
        NSAssert(location >= 0, @"No location for `directionalLightInvDirection`.");
        _directionalLightInvDirectionUniformLocation = (GLuint)location;

        location = glGetUniformLocation(_templeProgram, "directionalLightColor");
        NSAssert(location >= 0, @"No location for `directionalLightColor`.");
        _directionalLightColorUniformLocation = location;

        _templeMVPUniformLocation = glGetUniformLocation(_templeProgram, "modelViewProjectionMatrix");
    }
}

- (void) buildReflectiveQuadObjects
{
#if RENDER_REFLECTION
    // Setup vertex buffers and array object for the reflective quad.
    {
        static const AAPLQuadVertex AAPLQuadVertices[] =
        {
            { { -500, -500, 0.0, 1.0}, {1.0, 0.0} },
            { { -500,  500, 0.0, 1.0}, {1.0, 1.0} },
            { {  500,  500, 0.0, 1.0}, {0.0, 1.0} },

            { { -500, -500, 0.0, 1.0}, {1.0, 0.0} },
            { {  500,  500, 0.0, 1.0}, {0.0, 1.0} },
            { {  500, -500, 0.0, 1.0}, {0.0, 0.0} },
        };

        glGenBuffers(1, &_reflectionQuadBuffer);

        glBindBuffer(GL_ARRAY_BUFFER, _reflectionQuadBuffer);

        glBufferData(GL_ARRAY_BUFFER, sizeof(AAPLQuadVertices), AAPLQuadVertices, GL_STATIC_DRAW);

        glGenVertexArrays(1, &_reflectionQuadVAO);

        glBindVertexArray(_reflectionQuadVAO);

        glBindBuffer(GL_ARRAY_BUFFER, _reflectionQuadBuffer);

        glVertexAttribPointer(AAPLVertexAttributePosition, 4, GL_FLOAT, GL_FALSE,
                              sizeof(AAPLQuadVertex), BUFFER_OFFSET(0));
        glEnableVertexAttribArray(AAPLVertexAttributePosition);

        glVertexAttribPointer(AAPLVertexAttributeTexcoord, 2, GL_FLOAT, GL_FALSE,
                              sizeof(AAPLQuadVertex), BUFFER_OFFSET(offsetof(AAPLQuadVertex, texcoord)));
        glEnableVertexAttribArray(AAPLVertexAttributeTexcoord);

        GetGLError();
    }

    // Create texture and framebuffer objects to render and display the reflection.
    {
        // Create a texture object that you apply to the model.
        glGenTextures(1, &_reflectionColorTexture);
        glBindTexture(GL_TEXTURE_2D, _reflectionColorTexture);

        // Set up filter and wrap modes for the texture object.
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        // Mipmap generation is not accelerated on iOS, so you can't enable trilinear filtering.
#if TARGET_IOS
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
#else
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
#endif

        // Allocate a texture image to which you can render to. Pass `NULL` for the data parameter
        // becuase you don't need to load image data. You generate the image by rendering to the texture.
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
                     AAPLReflectionSize.x, AAPLReflectionSize.y, 0,
                     GL_RGBA, GL_UNSIGNED_BYTE, NULL);

        glGenRenderbuffers(1, &_reflectionDepthBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _reflectionDepthBuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24,
                              AAPLReflectionSize.x, AAPLReflectionSize.y);

        glGenFramebuffers(1, &_reflectionFBO);
        glBindFramebuffer(GL_FRAMEBUFFER, _reflectionFBO);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _reflectionColorTexture , 0);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _reflectionDepthBuffer);

        NSAssert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE,
                 @"Failed to make complete framebuffer object %x.", glCheckFramebufferStatus(GL_FRAMEBUFFER));

        GetGLError();
    }

    // Build the program object used to render the reflective quad.
    {
        NSURL *vertexSourceURL = [[NSBundle mainBundle] URLForResource:@"reflect" withExtension:@"vsh"];
        NSURL *fragmentSourceURL = [[NSBundle mainBundle] URLForResource:@"reflect" withExtension:@"fsh"];

        _reflectionProgram = [AAPLOpenGLRenderer buildProgramWithVertexSourceURL:vertexSourceURL
                                                          withFragmentSourceURL:fragmentSourceURL
                                                                      hasNormals:NO];

        _reflectionQuadMVPUniformLocation = glGetUniformLocation(_reflectionProgram, "modelViewProjectionMatrix");
    }
#endif
}

- (void)updateFrameState
{
    const vector_float3 ambientLightColor = {0.02, 0.02, 0.02};
    const vector_float3 directionalLightDirection = vector_normalize ((vector_float3){0.0, 0.0, 1.0});
    const vector_float3 directionalLightInvDirection = -directionalLightDirection;
    const vector_float3 directionalLightColor = {.7, .7, .7};

    const vector_float3   cameraPosition = {0.0, 0.0, -1000.0};
    const matrix_float4x4 cameraViewMatrix  = matrix4x4_translation(-cameraPosition);

    const vector_float3   templeRotationAxis      = {0, 1, 0};
    const matrix_float4x4 templeRotationMatrix    = matrix4x4_rotation (_rotation, templeRotationAxis);
    const matrix_float4x4 templeTranslationMatrix = matrix4x4_translation(0.0, -400, 0);
    const matrix_float4x4 templeModelMatrix       = matrix_multiply(templeRotationMatrix, templeTranslationMatrix);
    const matrix_float4x4 templeModelViewMatrix   = matrix_multiply (cameraViewMatrix, templeModelMatrix);
    const matrix_float3x3 templeNormalMatrix      = matrix3x3_upper_left(templeModelMatrix);

    _templeNormalMatrix           = templeNormalMatrix;
    _ambientLightColor            = ambientLightColor;
    _directionalLightInvDirection = directionalLightInvDirection;
    _directionalLightColor        = directionalLightColor;

    _templeCameraMVPMatrix        = matrix_multiply(_projectionMatrix, templeModelViewMatrix);

#if RENDER_REFLECTION
    const vector_float3  quadRotationAxis  = {1, 0, 0};
    const float          quadRotationAngle = 270 * M_PI/180;
    const vector_float3  quadTranslation   = {0, 300, 0};

    const matrix_float4x4 quadRotationMatrix            = matrix4x4_rotation(quadRotationAngle, quadRotationAxis);
    const matrix_float4x4 quadTranslationMatrtix        = matrix4x4_translation(quadTranslation);
    const matrix_float4x4 quadModelMatrix               = matrix_multiply(quadTranslationMatrtix, quadRotationMatrix);
    const matrix_float4x4 quadModeViewMatrix            = matrix_multiply(cameraViewMatrix, quadModelMatrix);

    const vector_float4 target = matrix_multiply(quadModelMatrix, (vector_float4){0, 0, 0, 1});
    const vector_float4 eye    = matrix_multiply(quadModelMatrix, (vector_float4){0.0, 0.0, 250, 1});
    const vector_float4 up     = matrix_multiply(quadModelMatrix, (vector_float4){0, 1, 0, 1});

    const matrix_float4x4 reflectionViewMatrix       = matrix_look_at_left_hand(eye.xyz, target.xyz, up.xyz);
    const matrix_float4x4 reflectionModelViewMatrix  = matrix_multiply(reflectionViewMatrix, templeModelMatrix);
    const matrix_float4x4 reflectionProjectionMatrix = matrix_perspective_left_hand_gl(M_PI/2.0, 1, 0.1, 3000.0);

    _templeReflectionMVPMatrix = matrix_multiply(reflectionProjectionMatrix, reflectionModelViewMatrix);

    _reflectionQuadMVPMatrix   = matrix_multiply(_projectionMatrix, quadModeViewMatrix);
#endif
    _rotation += .01;
}

- (void)resize:(CGSize)size
{
    // Handle the resize of the draw rectangle. In particular, update the perspective projection matrix
    // with a new aspect ratio because the view orientation, layout, or size has changed.
    _viewSize = size;
    float aspect = (float)size.width / size.height;
    _projectionMatrix = matrix_perspective_left_hand_gl(65.0f * (M_PI / 180.0f), aspect, 1.0f, 5000.0);
}

- (void)draw
{
    // Set up the model-view and projection matrices.
    [self updateFrameState];

    glUseProgram(_templeProgram);

    float packed3x3NormalMatrix[9] =
    {
        _templeNormalMatrix.columns[0].x,
        _templeNormalMatrix.columns[0].y,
        _templeNormalMatrix.columns[0].z,
        _templeNormalMatrix.columns[1].x,
        _templeNormalMatrix.columns[1].y,
        _templeNormalMatrix.columns[1].z,
        _templeNormalMatrix.columns[2].x,
        _templeNormalMatrix.columns[2].y,
        _templeNormalMatrix.columns[2].z,
    };

    glUniformMatrix3fv(_templeNormalMatrixUniformLocation, 1, GL_FALSE, packed3x3NormalMatrix);

    glUniform3fv(_ambientLightColorUniformLocation, 1, (GLvoid*)&_ambientLightColor);
    glUniform3fv(_directionalLightInvDirectionUniformLocation, 1, (GLvoid*)&_directionalLightInvDirection);
    glUniform3fv(_directionalLightColorUniformLocation, 1, (GLvoid*)&_directionalLightColor);

    glEnable(GL_DEPTH_TEST);

    glFrontFace(GL_CW);

    glCullFace(GL_BACK);

#if RENDER_REFLECTION

    // Bind the reflection FBO and render the scene.

    glBindFramebuffer(GL_FRAMEBUFFER, _reflectionFBO);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, AAPLReflectionSize.x, AAPLReflectionSize.y);
    // Use the program that renders the temple.
    glUseProgram(_templeProgram);

    glUniformMatrix4fv(_templeMVPUniformLocation, 1, GL_FALSE, (const GLfloat*)&_templeReflectionMVPMatrix);

    // Bind the vertex array object with the temple mesh vertices.
    glBindVertexArray(_templeVAO);

    // Draw the temple object to the reflection texture.
    for(GLuint i = 0; i < _numTempleSubmeshes; i++)
    {
        // Bind the texture to be used.
        glBindTexture(GL_TEXTURE_2D, _templeTextures[i]);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _templeIndexBuffers[i]);
        glDrawElements(GL_TRIANGLES, _templeIndexBufferCounts[i], GL_UNSIGNED_INT, 0);
    }
#if !TARGET_IOS
    // Generate mipmaps from the rendered-to base level. Mipmaps reduce shimmering pixels due to
    // better filtering. (iOS does not accelerate this call, so you don't use mipmaps in iOS.)

    glBindTexture(GL_TEXTURE_2D, _reflectionColorTexture);
    glGenerateMipmap(GL_TEXTURE_2D);

#endif

    // Bind the default FBO to render to the screen.
    glBindFramebuffer(GL_FRAMEBUFFER, _defaultFBOName);

    glViewport(0, 0, _viewSize.width, _viewSize.height);

#endif

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Use the program that renders the temple.
    glUseProgram(_templeProgram);

    glUniformMatrix4fv(_templeMVPUniformLocation, 1, GL_FALSE, (const GLfloat*)&_templeCameraMVPMatrix);

    // Bind the vertex array object with the temple mesh vertices.
    glBindVertexArray(_templeVAO);

    // Draw the temple object to the drawable.
    for(GLuint i = 0; i < _numTempleSubmeshes; i++)
    {
        // Bind the texture to be used.
        glBindTexture(GL_TEXTURE_2D, _templeTextures[i]);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _templeIndexBuffers[i]);
        glDrawElements(GL_TRIANGLES, _templeIndexBufferCounts[i], GL_UNSIGNED_INT, 0);
    }
#if RENDER_REFLECTION

    // Use the program that renders the reflective quad.
    glUseProgram(_reflectionProgram);

    glUniformMatrix4fv(_reflectionQuadMVPUniformLocation, 1, GL_FALSE, (const GLfloat*)&_reflectionQuadMVPMatrix);

    // Bind the texture that you previously render to (i.e. the reflection texture).
    glBindTexture(GL_TEXTURE_2D, _reflectionColorTexture);

    // Bind the quad vertex array object.
    glBindVertexArray(_reflectionQuadVAO);

    // Draw the refection plane.
    glDrawArrays(GL_TRIANGLES, 0, 6);

#endif
}

matrix_float4x4 matrix_perspective_left_hand_gl(float fovyRadians, float aspect, float nearZ, float farZ)
{
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = (farZ + nearZ) / (farZ - nearZ);
    float ws = -(2.f * farZ * nearZ) / (farZ - nearZ);

    return matrix_make_rows(xs,  0,  0,  0,
                             0, ys,  0,  0,
                             0,  0, zs, ws,
                             0,  0,  1,  0);
}

+ (GLuint)buildProgramWithVertexSourceURL:(NSURL*)vertexSourceURL
                    withFragmentSourceURL:(NSURL*)fragmentSourceURL
                               hasNormals:(BOOL)hasNormals
{
    NSError *error;



    NSString *vertSourceString = [[NSString alloc] initWithContentsOfURL:vertexSourceURL
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];

    NSAssert(vertSourceString, @"Could not load vertex shader source, error: %@.", error);

    NSString *fragSourceString = [[NSString alloc] initWithContentsOfURL:fragmentSourceURL
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];

    NSAssert(fragSourceString, @"Could not load fragment shader source, error: %@.", error);

    // Prepend the #version definition to the vertex and fragment shaders.
    float  glLanguageVersion;

#if TARGET_IOS
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "OpenGL ES GLSL ES %f", &glLanguageVersion);
#else
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);
#endif

    // `GL_SHADING_LANGUAGE_VERSION` returns the standard version form with decimals, but the
    //  GLSL version preprocessor directive simply uses integers (e.g. 1.10 should be 110 and 1.40
    //  should be 140). You multiply the floating point number by 100 to get a proper version number
    //  for the GLSL preprocessor directive.
    GLuint version = 100 * glLanguageVersion;

    NSString *versionString = [[NSString alloc] initWithFormat:@"#version %d", version];

    vertSourceString = [[NSString alloc] initWithFormat:@"%@\n%@", versionString, vertSourceString];
    fragSourceString = [[NSString alloc] initWithFormat:@"%@\n%@", versionString, fragSourceString];

    GLuint prgName;

    GLint logLength, status;

    // Create a program object.
    prgName = glCreateProgram();
    glBindAttribLocation(prgName, AAPLVertexAttributePosition, "inPosition");
    glBindAttribLocation(prgName, AAPLVertexAttributeTexcoord, "inTexcoord");

    if(hasNormals)
    {
        glBindAttribLocation(prgName, AAPLVertexAttributeNormal, "inNormal");
    }

    /*
     * Specify and compile a vertex shader.
     */

    GLchar *vertexSourceCString = (GLchar*)vertSourceString.UTF8String;
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, (const GLchar **)&(vertexSourceCString), NULL);
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);

    if (logLength > 0)
    {
        GLchar *log = (GLchar*) malloc(logLength);
        glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
        NSLog(@"Vertex shader compile log:\n%s.\n", log);
        free(log);
    }

    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);

    NSAssert(status, @"Failed to compile the vertex shader:\n%s.\n", vertexSourceCString);

    // Attach the vertex shader to the program.
    glAttachShader(prgName, vertexShader);

    // Delete the vertex shader because it's now attached to the program, which retains
    // a reference to it.
    glDeleteShader(vertexShader);

    /*
     * Specify and compile a fragment shader.
     */

    GLchar *fragSourceCString =  (GLchar*)fragSourceString.UTF8String;
    GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragShader, 1, (const GLchar **)&(fragSourceCString), NULL);
    glCompileShader(fragShader);
    glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(fragShader, logLength, &logLength, log);
        NSLog(@"Fragment shader compile log:\n%s.\n", log);
        free(log);
    }

    glGetShaderiv(fragShader, GL_COMPILE_STATUS, &status);

    NSAssert(status, @"Failed to compile the fragment shader:\n%s.", fragSourceCString);

    // Attach the fragment shader to the program.
    glAttachShader(prgName, fragShader);

    // Delete the fragment shader because it's now attached to the program, which retains
    // a reference to it.
    glDeleteShader(fragShader);

    /*
     * Link the program.
     */

    glLinkProgram(prgName);
    glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prgName, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s.\n", log);
        free(log);
    }

    glGetProgramiv(prgName, GL_LINK_STATUS, &status);

    NSAssert(status, @"Failed to link program.");

    glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prgName, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s.\n", log);
        free(log);
    }

    GLint samplerLoc = glGetUniformLocation(prgName, "baseColorMap");

    NSAssert(samplerLoc >= 0, @"No uniform location found from `baseColorMap`.");

    glUseProgram(prgName);

    // Indicate that the diffuse texture will be bound to texture unit 0.
    glUniform1i(samplerLoc, AAPLTextureIndexBaseColor);

    GetGLError();

    return prgName;
}

@end
