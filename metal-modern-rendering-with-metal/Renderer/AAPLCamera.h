/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class representing a 3D camera and data directly derived from it.
*/

#import <Foundation/Foundation.h>
#import <simd/simd.h>

#import "AAPLShaderTypes.h"

// A Camera objec used for rendering standard perspective or parallel setups.
// The camera object has only six writable properties:
//  `position`, `direction`, and `up` define the orientation and position of the camera
//  `nearPlane` and `farPlane` define the projection planes.
//  `viewAngle` defines the view angle in radians.
//  All other properties are generated from these values.
//  In addition, the renderer populates the `AAPLCameraParams` struct lazily to reduce CPU overhead.
@interface AAPLCamera : NSObject
{
    AAPLCameraParams    _cameraParams;      // Internally generated camera data used/defined by the renderer
    bool                _cameraParamsDirty; // Boolean value that denotes if the intenral data structure needs rebuilding

    // The camera uses either perspective or parallel projection, depending on a defined angle OR a defined width.
    float               _viewAngle;         // Full view angle inradians for perspective view; 0 for parallel view.
    float               _width;             // Width of back plane for parallel view; 0 for perspective view.

    simd::float3        _direction;         // Direction of the camera; is normalized.
    simd::float3        _position;          // Position of the camera/observer point.
    simd::float3        _up;                // Up direction of the camera; perpendicular to _direction.

    float               _nearPlane;         // Distance of the near plane to _position in world space.
    float               _farPlane;          // Distance of the far plane to _position in world space.
    float               _aspectRatio;       // Aspect ratio of the horizontal against the vertical (widescreen gives < 1.0 value).

    simd::float2        _projectionOffset;  // Offset projection (used by TAA or to stabilize cascaded shadow maps).

    simd::float3        _frustumCorners[8]; // Corners of the camera frustum in world space.
}

- (void)updateState;                        // Updates internal state from the various properties.

- (void)rotateOnAxis:(simd::float3) inAxis
             radians:(float) inRadians;     // Rotates camera around axis; updating many properties at once.

- (void)facePoint:(simd::float3)point
           withUp:(simd::float3)up;         // Faces the camera towards a point with a given up vector.

- (void)faceDirection:(simd::float3)forward // Faces the camera towards a direction with a given up vector.
               withUp:(simd::float3)up;

- (instancetype)initDefaultPerspective;
- (instancetype)initPerspectiveWithPosition:(simd::float3)position
                                  direction:(simd::float3) direction
                                         up:(simd::float3)up
                                  viewAngle:(float) viewAngle
                                aspectRatio:(float) aspectRatio
                                  nearPlane:(float) nearPlane
                                   farPlane:(float) farPlane;

- (instancetype)initParallelWithPosition:(simd::float3)position
                               direction:(simd::float3) direction
                                      up:(simd::float3)up
                                   width:(float) width
                                  height:(float) height
                               nearPlane:(float) nearPlane
                                farPlane:(float) farPlane;

@property (readonly)    AAPLCameraParams cameraParams; // Internally generated data; maps to `_cameraParams`.
@property (readonly)    simd::float3 left;       // Left of the camera.
@property (readonly)    simd::float3 right;      // Right of the camera.
@property (readonly)    simd::float3 down;       // Down direction of the camera.
@property (readonly)    simd::float3 forward;    // Facing direction of the camera (alias of direction).
@property (readonly)    simd::float3 backward;   // Backwards direction of the camera.

@property (readonly)    const simd::float3* frustumCorners;

@property (readonly)    bool isPerspective;      // Returns true if perspective (viewAngle != 0, width == 0).
@property (readonly)    bool isParallel;         // Returns true if perspective (width != 0, viewAngle == 0).
@property simd::float3  position;                // Position/observer point of the camera.
@property simd::float3  direction;               // Facing direction of the camera.
@property simd::float3  up;                      // Up direction of the camera; perpendicular to direction.
@property float         viewAngle;               // Full viewing angle in radians.
@property float         aspectRatio;             // Aspect ratio in width / height.
@property float         nearPlane;               // Distance from near plane to observer point (position).
@property float         farPlane;                // Distance from far plane to observer point (position).

@property simd::float2  projectionOffset;        // Offset projection (used by TAA or to stabilize cascaded shadow maps).

@end
