/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of class representing a 3D camera and data directly derived from it.
*/

#import "AAPLCamera.h"
using namespace simd;

// Generate look-at matrix. First generate the full matrix basis, then write out an inverse
// transform matrix.
static float4x4 sInvMatrixLookat(float3 inEye, float3 inTo, float3 inUp)
{
    float3 z = normalize(inTo - inEye);
    float3 x = normalize(cross(inUp, z));
    float3 y = cross(z, x);
    float3 t = (float3) { -dot(x, inEye), -dot(y, inEye), -dot(z, inEye) };
    return float4x4  (  float4 { x.x, y.x, z.x, 0 },
                        float4 { x.y, y.y, z.y, 0 },
                        float4 { x.z, y.z, z.z, 0 },
                        float4 { t.x, t.y, t.z, 1 } );
}

// Helper function to normalize a plane equation so the plane direction is normalized to 1 this
//  results in `dot(x, plane.xyz)+plane.w` giving the actual distance to the plane.
static simd::float4 sPlaneNormalize(const simd::float4& inPlane)
{
    return inPlane / simd::length(inPlane.xyz);
}

@implementation AAPLCamera : NSObject

// Helper function called after up updated. Adjusts forward/direction to stay orthogonal when
//  creating a more defined basis, do not set axis independently, but use `rotate()` or `setBasis()`
//  functions to update all at once.
-(void) orthogonalizeFromNewUp:(float3) newUp
{
    _up = normalize(newUp);
    float3 right = normalize(cross(_direction, _up));
    _direction = (cross(_up, right));
}

// Helper function called after forward updated.  Adjusts up to stay orthogonal when creating a
//  more defined basis, do not set axis independently, but use `rotate()` or `setBasis()` functions
//  to update all at once.
-(void) orthogonalizeFromNewForward:(float3) newForward
{
    _direction = normalize(newForward);
    float3 right = normalize(cross(_direction, _up));
    _up = cross(right, _direction);
}

// Helper function to face something with an up direction to easily look at a point in the scene.
-(void)facePoint:(float3)point withUp:(float3)up
{
    _direction = normalize(point-_position);
    float3 right = normalize(cross(_direction, up));
    _up = cross(right, _direction);
}

// Helper function to face something with an up direction to easily look at a point in the scene.
-(void)faceDirection:(simd::float3)forward withUp:(simd::float3)up
{
    _direction = normalize(forward);
    float3 right = normalize(cross(_direction, up));
    _up = cross(right, _direction);
}

// Initializes a perspective projective camera with parameters.
-(instancetype) initPerspectiveWithPosition:(simd::float3)position
                                  direction:(simd::float3) direction
                                         up:(simd::float3)up
                                  viewAngle:(float) viewAngle
                                aspectRatio:(float) aspectRatio
                                  nearPlane:(float) nearPlane
                                   farPlane:(float) farPlane
{
    self = [super init];
    _up              = up;
    [self orthogonalizeFromNewForward:direction];
    _position        = position;
    _width           = 0;
    _viewAngle       = viewAngle;
    _aspectRatio     = aspectRatio;
    _nearPlane       = nearPlane;
    _farPlane        = farPlane;
    _cameraParamsDirty = true;
    return self;
}

// Initializes a default perspective projective camera.
-(instancetype) initDefaultPerspective
{
    return [self initPerspectiveWithPosition:(float3) { 14.04f, 1.195f, 3.155f}
                             direction:(float3) { 0.98, -0.01, -0.16 }
                                    up:(float3) { 0, 1, 0}
                             viewAngle:3.14159265f / 3.0f
                           aspectRatio:1.0f
                             nearPlane:0.1f
                              farPlane:1000.0f];
}

// Initializes a default parallel projective camera.
-(instancetype) initParallelWithPosition:(simd::float3) position
                               direction:(simd::float3) direction
                                      up:(simd::float3) up
                                   width:(float) width
                                  height:(float) height
                               nearPlane:(float) nearPlane
                                farPlane:(float) farPlane
{
    self = [super init];
    _up              = up;
    [self orthogonalizeFromNewForward:direction];
    _position        = position;
    _width           = width;
    _viewAngle       = 0;
    _aspectRatio     = width / height;
    _nearPlane       = nearPlane;
    _farPlane        = farPlane;
    _cameraParamsDirty = true;
    return self;
}

// Is the camera using perspective projection?
-(bool) isPerspective
{
    return _viewAngle != 0.0f;
}

// Is the camera using parallel projection?
-(bool) isParallel
{
    return _viewAngle == 0.0f;
}

// Updates internal data to reflect new direction, up and position properties of the object.
-(void) updateState
{
    // Generate the view matrix from a matrix lookat.
    _cameraParams.viewMatrix = sInvMatrixLookat(_position, _position + _direction, _up);

    float px = _projectionOffset.x;
    float py = _projectionOffset.y;

    // Generate projection matrix from viewing angle and plane distances.
    if (_viewAngle != 0)
    {
        float va_tan = 1.0f / tanf(_viewAngle * 0.5);
        float ys = va_tan;
        float xs = ys / _aspectRatio;
        float zs = _farPlane / (_farPlane - _nearPlane);
        _cameraParams.projectionMatrix = float4x4( (float4)  { xs, 0, 0, 0},
                                                 (float4)  {  0,ys, 0, 0},
                                                 (float4)  { px,py,zs, 1},
                                                 (float4)  {  0, 0, -_nearPlane * zs, 0 } );

    }
    else // Generate parallel  matrix from width, height and plane distances.
    {

        float ys = 2.0f / _width;
        float xs = ys / _aspectRatio;
        float zs = 1.0f / (_farPlane - _nearPlane);
        _cameraParams.projectionMatrix = float4x4( (float4)  { xs, 0, 0, 0 },
                                                 (float4)  {  0,ys, 0, 0 },
                                                 (float4)  {  0, 0,zs, 0 },
                                                 (float4)  { px, py, -_nearPlane * zs, 1 } );
    }

    // Derived matrices.
    _cameraParams.viewProjectionMatrix              = _cameraParams.projectionMatrix * _cameraParams.viewMatrix;
    _cameraParams.invProjectionMatrix               = simd_inverse(_cameraParams.projectionMatrix);
    _cameraParams.invViewProjectionMatrix           = simd_inverse(_cameraParams.viewProjectionMatrix);
    _cameraParams.invViewMatrix                     = simd_inverse(_cameraParams.viewMatrix);

    float4x4 transp_vpm = simd::transpose(_cameraParams.viewProjectionMatrix);
    _cameraParams.worldFrustumPlanes[0]              = sPlaneNormalize(transp_vpm.columns[3] + transp_vpm.columns[0]);    // Left plane eq.
    _cameraParams.worldFrustumPlanes[1]              = sPlaneNormalize(transp_vpm.columns[3] - transp_vpm.columns[0]);    // Right plane eq.
    _cameraParams.worldFrustumPlanes[2]              = sPlaneNormalize(transp_vpm.columns[3] + transp_vpm.columns[1]);    // Up plane eq.
    _cameraParams.worldFrustumPlanes[3]              = sPlaneNormalize(transp_vpm.columns[3] - transp_vpm.columns[1]);    // Down plane eq.
    _cameraParams.worldFrustumPlanes[4]              = sPlaneNormalize(transp_vpm.columns[3] + transp_vpm.columns[2]);    // Near plane eq.
    _cameraParams.worldFrustumPlanes[5]              = sPlaneNormalize(transp_vpm.columns[3] - transp_vpm.columns[2]);    // Far plane eq.

    // Inverse Column.
    _cameraParams.invProjZ = (simd::float4) { _cameraParams.invProjectionMatrix.columns[2].z, _cameraParams.invProjectionMatrix.columns[2].w,
                                            _cameraParams.invProjectionMatrix.columns[3].z, _cameraParams.invProjectionMatrix.columns[3].w};

    float invScale                              = _farPlane - _nearPlane;
    float bias                                  = -_nearPlane;

    _cameraParams.invProjZNormalized        = (simd::float4) { _cameraParams.invProjZ.x + (_cameraParams.invProjZ.y * bias), _cameraParams.invProjZ.y * invScale,
                                                           _cameraParams.invProjZ.z + (_cameraParams.invProjZ.w * bias), _cameraParams.invProjZ.w * invScale};

    //Update frustum corners.
    {
        // Get the 8 points of the view frustum in world space.
        _frustumCorners[0] = float3{-1.0f,  1.0f, 0.0f};
        _frustumCorners[1] = float3{ 1.0f,  1.0f, 0.0f};
        _frustumCorners[2] = float3{ 1.0f, -1.0f, 0.0f};
        _frustumCorners[3] = float3{-1.0f, -1.0f, 0.0f};
        _frustumCorners[4] = float3{-1.0f,  1.0f, 1.0f};
        _frustumCorners[5] = float3{ 1.0f,  1.0f, 1.0f};
        _frustumCorners[6] = float3{ 1.0f, -1.0f, 1.0f};
        _frustumCorners[7] = float3{-1.0f, -1.0f, 1.0f};

        float4x4 invViewProjMatrix = _cameraParams.invViewProjectionMatrix;

        for(uint j = 0; j < 8; ++j)
        {
            float4 corner = invViewProjMatrix * float4{_frustumCorners[j].x, _frustumCorners[j].y, _frustumCorners[j].z, 1.0f};
            _frustumCorners[j] = corner.xyz / corner.w;
        }
    }

    // Data are updated and no longer dirty.
    _cameraParamsDirty = false;
}

// All other directions are derived from the  -up and _direction instance variables.
-(float3) left                            { return simd_cross(_direction, _up); }
-(float3) right                           { return -self.left; }
-(float3) down                            { return -self.up; }
-(float3) forward                         { return self.direction; }
-(float3) backward                        { return -self.direction; }

-(float) nearPlane                        { return _nearPlane; }
-(float) farPlane                         { return _farPlane; }
-(float) aspectRatio                      { return _aspectRatio; }
-(float) viewAngle                        { return _viewAngle; }
-(float) width                            { return _width; }
-(float3) up                              { return _up; }
-(float3) position                        { return _position; }
-(float3) direction                       { return _direction; }

-(float2) projectionOffset                { return _projectionOffset; }

-(const float3*) frustumCorners                 { if (_cameraParamsDirty) [self updateState]; return _frustumCorners; }

// For the camera data getter, we first check the dirty flag and re-calculate the values if needed.
-(AAPLCameraParams)cameraParams                     { if (_cameraParamsDirty) [self updateState]; return _cameraParams;}

// For all the setter functions, we update the instance variables and set the dirty flag.
-(void)setNearPlane:(float)newNearPlane         { _nearPlane    = newNearPlane;                     _cameraParamsDirty = true; }
-(void)setFarPlane:(float)newFarPlane           { _farPlane     = newFarPlane;                      _cameraParamsDirty = true; }
-(void)setAspectRatio:(float)newAspectRatio     { _aspectRatio  = newAspectRatio;                   _cameraParamsDirty = true; }
-(void)setViewAngle:(float)newAngle             { assert(_width == 0); _viewAngle = newAngle;       _cameraParamsDirty = true; }
-(void)setWidth:(float)newWidth                 { assert(_viewAngle == 0); _width = newWidth;       _cameraParamsDirty = true; }
-(void)setPosition:(float3)newPosition          { _position     = newPosition;                      _cameraParamsDirty = true; }
-(void)setUp:(float3)newUp                      { [self orthogonalizeFromNewUp: newUp];             _cameraParamsDirty = true; }
-(void)setDirection:(float3)newDirection        { [self orthogonalizeFromNewForward: newDirection]; _cameraParamsDirty = true; }

-(void)setProjectionOffset:(simd::float2)projectionOffset   { _projectionOffset = projectionOffset; _cameraParamsDirty = true; }

-(float4x4) viewMatrix                          { return _cameraParams.viewMatrix; }
-(float4x4) projectionMatrix                    { return _cameraParams.projectionMatrix; }
-(float4x4) viewProjectionMatrix                { return _cameraParams.viewProjectionMatrix; }
-(float4x4) invViewProjectionMatrix             { return _cameraParams.invViewProjectionMatrix; }
-(float4x4) invProjectionMatrix                 { return _cameraParams.invProjectionMatrix; }
-(float4x4) invViewMatrix                       { return _cameraParams.invViewMatrix; }

// Rotates the camera on an axis; it rotates both direction and up to keep the orthogonal base intact.
-(void) rotateOnAxis:(float3)inAxis radians:(float)inRadians
{
    // Generate rotation matrix along inAxis.
    float3 axis         = normalize(inAxis);
    float ct            = cosf(inRadians);
    float st            = sinf(inRadians);
    float ci            = 1 - ct;
    float x             = axis.x;
    float y             = axis.y;
    float z             = axis.z;
    float3x3 mat        ( (float3) { ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st } ,
                          (float3) { x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st } ,
                          (float3) { x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci } );

    // Apply to basis vectors.
    _direction          = simd_mul(_direction, mat);
    _up                 = simd_mul(_up, mat);
    _cameraParamsDirty    = true;
}

@end

