/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class controlling the position of a 3D camera.
*/

#import <Foundation/Foundation.h>
#import <simd/types.h>
#import <vector>

@class AAPLCamera;

// Stores a list of keypoints.
//  Supports attaching to a camera, then updates to the controller time with
//  `updateTimeInSeconds` updates the camera transform.
//  Keypoints can be added and removed and serialized to/from file.
@interface AAPLCameraController : NSObject

- (nonnull instancetype)init;

// Runtime usage - attach, update or move to a new keypoint.
- (void)attachToCamera:(nonnull AAPLCamera*)camera;

- (void)updateTimeInSeconds:(CFAbsoluteTime)seconds;

- (void)moveTo:(uint)index;

// Keypoint access and modification.
- (void)addKeypointAt:(simd::float3)position
                       forward:(simd::float3)forward
                            up:(simd::float3)up
                      lightEnv:(float)lightEnv;

- (void)updateKeypoint:(uint)index
                       position:(simd::float3)position
                        forward:(simd::float3)forward
                             up:(simd::float3)up;

- (void)clearKeypoints;

- (void)popKeypoint;

- (void)getKeypoints:(std::vector<simd::float3> &)outKeypoints
                  outForwards:(std::vector<simd::float3> &)outForwards;

- (void)getLightEnv:(float&)outInterp
                        outA:(uint&)outA
                        outB:(uint&)outB;

- (void)saveKeypointToFile:(nonnull NSString*)file;

- (bool)loadKeypointFromFile:(nonnull NSString*)file;

// Multiplier for update time to control movement speed.
@property float movementSpeed;
// Total length of path in seconds.
@property (nonatomic, readonly) float totalDistance;
// Flag to indicate that this controller is enabled.
@property bool enabled;

@property (nonatomic, readonly) uint keypointCount;

@end
