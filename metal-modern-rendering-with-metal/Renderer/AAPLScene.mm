/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of class managing objects in the 3D scene.
*/

#import "AAPLScene.h"

#import "AAPLRenderer.h"
#import "AAPLCamera.h"
#import "AAPLInput.h"
#import "AAPLCommon.h"
#import "AAPLMathUtilities.h"

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import <vector>

#define SPOT_LIGHT_INNER_SCALE (0.8f)

using namespace simd;

@implementation AAPLScene
{
    id<MTLDevice> _device;

    NSString* _name;

    std::vector<AAPLPointLightData> _pointLights;
    std::vector<AAPLSpotLightData>  _spotLights;

    id<MTLBuffer>                   _occluderVertexBuffer;
    id<MTLBuffer>                   _occluderIndexBuffer;

    simd::float3                    _centerOffset;
    std::vector<uint16_t>           _occluderIndices;
    std::vector<simd::float3>       _occluderVerts;
    std::vector<simd::float3>       _occluderVertsTransformed;
}

- (nonnull instancetype) initWithDevice:(nonnull id<MTLDevice>)device
{
    self = [super init];
    if(self)
    {
        _device = device;
    }
    return self;
}

- (AAPLPointLightData*) pointLights { return &_pointLights[0]; }
- (AAPLSpotLightData*)  spotLights  { return &_spotLights[0]; }

- (NSUInteger) pointLightCount  { return _pointLights.size(); }
- (NSUInteger) spotLightCount   { return _spotLights.size(); }

- (void) addPointLight:(simd::float3)position radius:(float)radius color:(simd::float3)color flags:(uint)flags
{
    _pointLights.push_back({ make_float4(position, radius), color, flags });
}

- (void) addSpotLight:(simd::float3)pos
                  dir:(simd::float3)dir
               height:(float)height
                angle:(float)angle
                color:(simd::float3)color
                flags:(uint)flags
{
    AAPLSpotLightData spotLight;

    simd::float4 boundingSphere;
    if(angle > M_PI/4.0f)
    {
        float R = height * tanf(angle);
        boundingSphere.xyz = pos + height * dir;
        boundingSphere.w = R;
    }
    else
    {
        float R = height / (2 * cos(angle) * cos(angle));
        boundingSphere.xyz = pos + dir * R;
        boundingSphere.w = R;
    }
    spotLight.boundingSphere        = boundingSphere;
    spotLight.dirAndOuterAngle      = simd::make_float4(dir.xyz, angle);
    spotLight.posAndHeight          = simd::make_float4(pos.xyz, height);
    spotLight.colorAndInnerAngle    = simd::make_float4(color.xyz, angle * SPOT_LIGHT_INNER_SCALE);
    spotLight.flags                 = flags;

    const float spotNearClip = 0.1f;
    const float spotFarClip = height;
    matrix_float4x4 viewMatrix = matrix_look_at_left_hand(pos.xyz, pos.xyz + dir.xyz, make_float3(0.0f, 1.0f, 0.0f));
    float va_tan = 1.0f / tanf(angle * 2.0 * 0.5);
    float ys = va_tan;
    float xs = ys;
    float zs = spotFarClip / (spotFarClip - spotNearClip);
    matrix_float4x4 projMatrix = float4x4(  (float4)  { xs, 0, 0, 0 },
                                          (float4)  {  0,ys, 0, 0 },
                                          (float4)  {  0, 0,zs, 1 },
                                          (float4)  {  0, 0, -spotNearClip * zs, 0 } );

    spotLight.viewProjMatrix = projMatrix * viewMatrix;

    _spotLights.push_back(spotLight);
}

- (void) clearLights
{
    _spotLights.resize(0);
    _pointLights.resize(0);
}

//----------------------------------------------------------------------

- (void) saveToFile:(NSString*)name
{
    if(name != nil)
        _name = name;

    NSString* filename = [NSString stringWithFormat:@"%@/%@.scene", getOrCreateApplicationSupportPath(), _name];
    NSOutputStream *os = [[NSOutputStream alloc] initToFileAtPath:filename append:NO];

    NSMutableDictionary *scene = [[NSMutableDictionary alloc] init];

    //----------------------------------------------------------------------
    //----------------------------------------------------------------------

    {
        NSMutableArray *centerOffset = [[NSMutableArray alloc] init];

        [centerOffset addObject:@(_centerOffset.x)];
        [centerOffset addObject:@(_centerOffset.y)];
        [centerOffset addObject:@(_centerOffset.z)];

        [scene setObject:centerOffset forKey:@"center_offset"];
    }

    //----------------------------------------------------------------------
    //----------------------------------------------------------------------

    {
        [scene setObject:_meshFilename forKey:@"mesh_filename"];

        NSMutableArray *cameraPosition = [[NSMutableArray alloc] init];

        [cameraPosition addObject:@(_cameraPosition.x)];
        [cameraPosition addObject:@(_cameraPosition.y)];
        [cameraPosition addObject:@(_cameraPosition.z)];

        [scene setObject:cameraPosition forKey:@"camera_position"];

        NSMutableArray *cameraDirection = [[NSMutableArray alloc] init];

        [cameraDirection addObject:@(_cameraDirection.x)];
        [cameraDirection addObject:@(_cameraDirection.y)];
        [cameraDirection addObject:@(_cameraDirection.z)];

        [scene setObject:cameraDirection forKey:@"camera_direction"];

        NSMutableArray *cameraUp = [[NSMutableArray alloc] init];

        [cameraUp addObject:@(_cameraUp.x)];
        [cameraUp addObject:@(_cameraUp.y)];
        [cameraUp addObject:@(_cameraUp.z)];

        [scene setObject:cameraUp forKey:@"camera_up"];

        [scene setObject:_cameraKeypointsFilename forKey:@"camera_keypoints_filename"];

        NSMutableArray *sunDirection = [[NSMutableArray alloc] init];

        [sunDirection addObject:@(_sunDirection.x)];
        [sunDirection addObject:@(_sunDirection.y)];
        [sunDirection addObject:@(_sunDirection.z)];

        [scene setObject:sunDirection forKey:@"sun_direction"];
    }

    //----------------------------------------------------------------------
    //----------------------------------------------------------------------

    NSMutableArray *pointLights = [[NSMutableArray alloc] init];

    for(int i = 0; i < _pointLights.size(); i++)
    {
        NSMutableDictionary *light = [[NSMutableDictionary alloc] init];

        [light setObject:@(_pointLights[i].posSqrRadius.x)  forKey:@"position_x"];
        [light setObject:@(_pointLights[i].posSqrRadius.y)  forKey:@"position_y"];
        [light setObject:@(_pointLights[i].posSqrRadius.z)  forKey:@"position_z"];
        [light setObject:@(_pointLights[i].posSqrRadius.w)  forKey:@"sqrt_radius"];

        [light setObject:@(_pointLights[i].color.x)  forKey:@"color_r"];
        [light setObject:@(_pointLights[i].color.y)  forKey:@"color_g"];
        [light setObject:@(_pointLights[i].color.z)  forKey:@"color_b"];

        [light setObject:@(_pointLights[i].flags & LIGHT_FOR_TRANSPARENT_FLAG)  forKey:@"for_transparent"];

        [pointLights addObject:light];
    }

    NSMutableArray *spotLights = [[NSMutableArray alloc] init];

    for(int i = 0; i < _spotLights.size(); i++)
    {
        NSMutableDictionary *light = [[NSMutableDictionary alloc] init];

        [light setObject:@(_spotLights[i].posAndHeight.x)  forKey:@"position_x"];
        [light setObject:@(_spotLights[i].posAndHeight.y)  forKey:@"position_y"];
        [light setObject:@(_spotLights[i].posAndHeight.z)  forKey:@"position_z"];
        [light setObject:@(_spotLights[i].posAndHeight.w)  forKey:@"height"];

        [light setObject:@(_spotLights[i].dirAndOuterAngle.x)  forKey:@"direction_x"];
        [light setObject:@(_spotLights[i].dirAndOuterAngle.y)  forKey:@"direction_y"];
        [light setObject:@(_spotLights[i].dirAndOuterAngle.z)  forKey:@"direction_z"];
        [light setObject:@(_spotLights[i].dirAndOuterAngle.w)  forKey:@"coneRad"];

        [light setObject:@(_spotLights[i].colorAndInnerAngle.x)  forKey:@"color_r"];
        [light setObject:@(_spotLights[i].colorAndInnerAngle.y)  forKey:@"color_g"];
        [light setObject:@(_spotLights[i].colorAndInnerAngle.z)  forKey:@"color_b"];

        [light setObject:@(_spotLights[i].flags & LIGHT_FOR_TRANSPARENT_FLAG)  forKey:@"for_transparent"];

        [spotLights addObject:light];
    }

    [scene setObject:pointLights forKey:@"point_lights"];
    [scene setObject:spotLights forKey:@"spot_lights"];

    //----------------------------------------------------------------------
    //----------------------------------------------------------------------

    NSMutableArray *occluderVerts = [[NSMutableArray alloc] init];

    for(int i = 0; i < _occluderVerts.size(); i++)
    {
        NSMutableArray *vert = [[NSMutableArray alloc] init];

        [vert addObject:@(_occluderVerts[i].x)];
        [vert addObject:@(_occluderVerts[i].y)];
        [vert addObject:@(_occluderVerts[i].z)];

        [occluderVerts addObject:vert];
    }

    NSMutableArray *occluderIndices = [[NSMutableArray alloc] init];

    for(int i = 0; i < _occluderIndices.size(); i++)
        [occluderIndices addObject:@(_occluderIndices[i])];

    [scene setObject:occluderVerts forKey:@"occluder_verts"];
    [scene setObject:occluderIndices forKey:@"occluder_indices"];

    //----------------------------------------------------------------------
    //----------------------------------------------------------------------

    [os open];
    [NSJSONSerialization writeJSONObject:scene toStream:os options:NSJSONReadingMutableContainers error:nil];
    [os close];

    NSLog(@"Written scene to %@", filename);
}

- (bool) loadFromFile:(NSString*)name altSource:(BOOL)altSource
{
    _name = name;

    NSString* filename = nil;

    if(!altSource)
    {
        NSURL* url = [[NSBundle mainBundle] URLForResource:_name withExtension:@"scene"];

        if(!url)
            return false;

        filename = url.path;
    }
    else
    {
        filename = [NSString stringWithFormat:@"%@/%@.scene", getOrCreateApplicationSupportPath(), _name];
    }

    NSInputStream *is = [[NSInputStream alloc] initWithFileAtPath:filename];

    if(is == nil)
        return false;

    [is open];
    NSDictionary *scene = [NSJSONSerialization JSONObjectWithStream:is options:0 error:nil];
    [is close];

    //----------------------------------------------------------------------
    //----------------------------------------------------------------------

    NSArray *centerOffset = scene[@"center_offset"];
    _centerOffset = make_float3([centerOffset[0] floatValue], [centerOffset[1] floatValue], [centerOffset[2] floatValue]);

    //----------------------------------------------------------------------
    //----------------------------------------------------------------------

    _meshFilename = scene[@"mesh_filename"];

    NSArray *cameraPosition = scene[@"camera_position"];
    _cameraPosition = make_float3([cameraPosition[0] floatValue], [cameraPosition[1] floatValue], [cameraPosition[2] floatValue]);

    NSArray *cameraDirection = scene[@"camera_direction"];
    _cameraDirection = make_float3([cameraDirection[0] floatValue], [cameraDirection[1] floatValue], [cameraDirection[2] floatValue]);

    NSArray *cameraUp = scene[@"camera_up"];
    _cameraUp = make_float3([cameraUp[0] floatValue], [cameraUp[1] floatValue], [cameraUp[2] floatValue]);

    _cameraKeypointsFilename = scene[@"camera_keypoints_filename"];

    NSArray *sunDirection = scene[@"sun_direction"];
    _sunDirection = make_float3([sunDirection[0] floatValue], [sunDirection[1] floatValue], [sunDirection[2] floatValue]);

    //----------------------------------------------------------------------
    //----------------------------------------------------------------------

    _pointLights.clear();
    _spotLights.clear();

    NSArray *pointLights = scene[@"point_lights"];

    for (id e in pointLights)
    {
        AAPLPointLightData light;
        light.posSqrRadius = make_float4([e[@"position_x"] floatValue], [e[@"position_y"] floatValue], [e[@"position_z"] floatValue], [e[@"sqrt_radius"] floatValue]);
        light.color = make_float3([e[@"color_r"] floatValue], [e[@"color_g"] floatValue], [e[@"color_b"] floatValue]);
        light.flags = [e[@"for_transparent"] boolValue] ? LIGHT_FOR_TRANSPARENT_FLAG : 0;

        _pointLights.push_back(light);
    }

    //----------------------------------------------------------------------

    NSArray *spotLights = scene[@"spot_lights"];

    for (id e in spotLights)
    {
        float3 pos      = make_float3([e[@"position_x"] floatValue], [e[@"position_y"] floatValue], [e[@"position_z"] floatValue]);
        float3 dir      = make_float3([e[@"direction_x"] floatValue], [e[@"direction_y"] floatValue], [e[@"direction_z"] floatValue]);
        float height    = [e[@"height"] floatValue];
        float angle     = [e[@"coneRad"] floatValue];
        float3 color    = make_float3([e[@"color_r"] floatValue], [e[@"color_g"] floatValue], [e[@"color_b"] floatValue]);
        uint flags      = [e[@"for_transparent"] boolValue] ? LIGHT_FOR_TRANSPARENT_FLAG : 0;

        [self addSpotLight:pos dir:dir height:height angle:angle color:color flags:flags];
    }

    //----------------------------------------------------------------------
    //----------------------------------------------------------------------

    _occluderVerts.clear();
    _occluderVertsTransformed.clear();

    // Occluder vertices for meshes that can occlude the scene
    NSArray *occluderVerts = scene[@"occluder_verts"];

    for (id v in occluderVerts)
    {
        float3 vert = make_float3([v[0] floatValue], [v[1] floatValue], [v[2] floatValue]);

        _occluderVerts.push_back(vert);
    }

    for(int i = 0; i < _occluderVerts.size(); i++)
    {
        simd::float3 transformedVert = _occluderVerts[i];

        float t             = transformedVert.z;
        transformedVert.z   = transformedVert.y;
        transformedVert.y   = t;

        transformedVert -= _centerOffset;

        _occluderVertsTransformed.push_back(transformedVert);
    }

    // Occluder indices for meshes that can occlude the scene
    NSArray *occluderIndices = scene[@"occluder_indices"];

    for (id i in occluderIndices)
    {
        _occluderIndices.push_back([i unsignedIntValue]);
    }

    size_t vertexBufferSize = sizeof(_occluderVertsTransformed[0])*_occluderVertsTransformed.size();

    _occluderVertexBuffer = [_device newBufferWithLength:vertexBufferSize options:0];
    memcpy(_occluderVertexBuffer.contents, &_occluderVertsTransformed[0], vertexBufferSize);
    _occluderVertexBuffer.label = @"Occluder Vertices";

    size_t indexBufferSize  = sizeof(uint16_t)*_occluderIndices.size();

    _occluderIndexBuffer = [_device newBufferWithLength:indexBufferSize options:0];
    memcpy(_occluderIndexBuffer.contents, &_occluderIndices[0], indexBufferSize);
    _occluderIndexBuffer.label = @"Occluder Indices";

    //----------------------------------------------------------------------
    //----------------------------------------------------------------------

    NSLog(@"Read scene from %@", filename);

    return true;
}

@end
