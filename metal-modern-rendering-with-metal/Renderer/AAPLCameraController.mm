/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of class controlling the position of a 3D camera.
*/
#import "AAPLRenderer.h"
#import "AAPLCameraController.h"
#import "AAPLCamera.h"
#import "AAPLInput.h"
#import "AAPLCommon.h"

#import <simd/simd.h>
#import <vector>

using namespace simd;

// Internal structure of a keypoint.
struct AAPLCameraKeypoint
{
    // Constructors.
    AAPLCameraKeypoint()
        : lightEnv(0.0f) {}
    AAPLCameraKeypoint(simd::float3 pos, simd::float3 forward, simd::float3 up, uint lightEnv)
        : position(pos)
        , forward(forward)
        , up(up)
        , lightEnv(lightEnv) {}

    simd::float3 position;  // Position of the keypoint.
    simd::float3 forward;   // Forward direction at the keypoint.
    simd::float3 up;        // Up direction at the keypoint.
    uint lightEnv;          // Selected light environment at the keypoint.
};

@implementation AAPLCameraController
{
    // The camera attached to this controller.
    AAPLCamera* _attachedCamera;
    // Current progress throught the keypoints.
    float _progress;
    // Storage for the keypoints.
    std::vector<AAPLCameraKeypoint> _keypoints;
    // Internal array of distances to keypoints from first keypoint.
    std::vector<float> _distances;
    // Total of all the keypoint distances.
    float _totalDistance;

    // Flag to indicate looping mode:
    //  Looping mode interpolates from end to start
    //  Otherwise it resets to the start after the end with no interpolation.
    bool _loop;
    // Flag to indicate that custom distances were loaded from file and should
    //  not be overwritten.
    bool _loadedDistances;

    // Current light environment interpolation.
    uint _lightEnvA;
    uint _lightEnvB;
    float _lightEnvInterp;
}

-(void) clearKeypoints
{
    _keypoints.clear();
}

-(instancetype) init
{
    self = [super init];

    _movementSpeed = 1.0f;
    _totalDistance = 0.0f;
    _loop = false;
    _enabled = false;
    _loadedDistances = false;

    _lightEnvA = 0;
    _lightEnvB = 0;
    _lightEnvInterp = 0.0f;

    return self;
}

- (void) getLightEnv:(float&)outInterp
                outA:(uint&)outA
                outB:(uint&)outB
{
    outInterp = _lightEnvInterp;
    outA = _lightEnvA;
    outB = _lightEnvB;
}

-(float) totalDistance
{
    return _totalDistance;
}
-(uint) keypointCount
{
    return (uint)_keypoints.size();
}

-(void) moveTo:(uint)index
{
    if(index < _keypoints.size())
    {
        _progress = index > 0 ? _distances[index-1] : 0.0f;
    }
}

// Internal method to calculate length limit for keypoint path.
-(float) length
{
    return _totalDistance > 0.0f ? _totalDistance : float(_keypoints.size());
}

// Internal method to calculate the index of the element at time t.
-(uint) indexFor:(float)time t:(float &)t
{
    if(_totalDistance == 0.0f)
    {
        t = fmod(time, 1.0f);
        return (uint)time;
    }

    float lastDistance = 0.0f;
    for(int i = 0 ; i < _distances.size() ; i++)
    {
        if(time < _distances[i])
        {
            t = (time - lastDistance) / (_distances[i] - lastDistance);
            return i;
        }
        lastDistance = _distances[i];
    }
    t = 0.0f;
    return 0;
}

// Internal method to populate the _distances array.
-(void) updateDistances
{
    _totalDistance = 0.0f; // Use linear mode for getPositionAt
    float totalDistance = 0.0f; // Accumulate locally

    simd::float3 p = [self getPositionAt:0.0f];

    uint length = (uint) _keypoints.size();
    _distances.resize(length);
    for (uint i = 0; i < length; i++)
    {
        const uint steps = 32;
        float distance = 0.0f;
        for(uint j = 0 ; j < steps ; j++)
        {
            simd::float3 q = [self getPositionAt:(i + (j / (float)steps)) ];
            distance += simd::length(p-q);
            p = q;
        }
        totalDistance += distance;
        _distances[i] = totalDistance;
    }
    _totalDistance = totalDistance;
}

// Internal method to calculate the indices for interpolation at time t.
-(void) getIndicesAt:(float)time
                   t:(float &)t
                 kp0:(uint &)kp0
                 kp1:(uint &)kp1
                 kp2:(uint &)kp2
              kpprev:(uint &)kpprev
{
    float loopedTime = fmod(time, self.length);
    kp0 = [self indexFor:loopedTime t:t];
    if(_loop)
    {
        kp1 = (kp0 + 1) % _keypoints.size();
        kp2 = (kp0 + 2) % _keypoints.size();
        kpprev = (kp0 +  (int) _keypoints.size() - 1) % _keypoints.size();
    }
    else
    {
        kp1 = std::min(kp0 + 1, (uint)_keypoints.size() - 1);
        kp2 = std::min(kp0 + 2, (uint)_keypoints.size() - 1);
        kpprev = std::max((int)kp0 - 1, 0);
    }
}

// Internal function to perform the interpolation for interpolant t.
+(simd::float3) interpolateForT:(float)t
    p0:(simd::float3)p0
    p1:(simd::float3)p1
    p2:(simd::float3)p2
 pprev:(simd::float3)pprev
{
    float i = t;
    float i2 = i * i;
    float i3 = i * i * i;

    simd::float3 m0 = ((p1 - p0) + (p0 - pprev)) * .5f;
    simd::float3 m1 = ((p2 - p1) + (p1 - p0)) * .5f;

    simd::float3 pos =  p0 * (2.0f * i3 - 3 * i2 + 1.0f);
    pos +=              p1 * (-2.0f * i3 + 3 * i2);
    pos +=              m0 * (i3 - 2 * i2 + i);
    pos +=              m1 * (i3 - i2);

    return pos;
}

-(simd::float3) getPositionAt:(float)time
{
    if (_keypoints.size() == 1) return _keypoints[0].position;

    float t;
    uint kp0, kp1, kp2, kpprev;
    [self getIndicesAt:time t:t kp0:kp0 kp1:kp1 kp2:kp2 kpprev:kpprev];

    simd::float3 p0 = _keypoints[kp0].position;
    simd::float3 p1 = _keypoints[kp1].position;
    simd::float3 p2 = _keypoints[kp2].position;
    simd::float3 pprev = _keypoints[kpprev].position;

    return [[self class] interpolateForT:t p0:p0 p1:p1 p2:p2 pprev:pprev];
}

-(simd::float3) getForwardAt:(float)time
{
    if (_keypoints.size() == 1) return _keypoints[0].forward;

    float t;
    uint kp0, kp1, kp2, kpprev;
    [self getIndicesAt:time t:t kp0:kp0 kp1:kp1 kp2:kp2 kpprev:kpprev];

    simd::float3 p0 = _keypoints[kp0].forward;
    simd::float3 p1 = _keypoints[kp1].forward;
    simd::float3 p2 = _keypoints[kp2].forward;
    simd::float3 pprev = _keypoints[kpprev].forward;

    return [[self class] interpolateForT:t p0:p0 p1:p1 p2:p2 pprev:pprev];
}

-(void) getLightEnvAt:(float)time outA:(uint&)outA outB:(uint&)outB outInterp:(float&)outInterp
{
    if (_keypoints.size() == 1)
    {
        outA        = _keypoints[0].lightEnv;
        outB        = _keypoints[0].lightEnv;
        outInterp = 0.0f;
    }

    float loopedTime = fmod(time, self.length);

    float t;
    uint kp0 = [self indexFor:loopedTime t:t];
    uint kpprev = (kp0 +  (int) _keypoints.size() - 1) % _keypoints.size();

    if(!_loop)
    {
        kpprev = std::max((int)kp0 - 1, 0);
    }

    uint p0     = _keypoints[kp0].lightEnv;
    uint pprev  = _keypoints[kpprev].lightEnv;

    outA = pprev;
    outB = p0;
    outInterp = t;
}

-(void) updateTimeInSeconds:(CFAbsoluteTime)seconds
{
    if (_keypoints.size() < 2)
        return;

    _progress += seconds * _movementSpeed;
    _progress = fmod(_progress, self.length);

    simd::float3 pos = [self getPositionAt:_progress];
    _attachedCamera.position = pos;
    [_attachedCamera faceDirection:[self getForwardAt:_progress] withUp:(simd::float3) {0,1,0}];

    [self getLightEnvAt:_progress outA:_lightEnvA outB:_lightEnvB outInterp:_lightEnvInterp];
}

-(void) attachToCamera:(AAPLCamera*)camera
{
    _attachedCamera = camera;
    _progress = 0;
}

-(void) addKeypointAt:(simd::float3)position forward:(simd::float3)forward up:(simd::float3)up lightEnv:(float)lightEnv
{
    _keypoints.push_back(AAPLCameraKeypoint(position, forward, up, lightEnv));
}

-(void) updateKeypoint:(uint)index position:(simd::float3)position forward:(simd::float3)forward up:(simd::float3)up
{
    if(index < _keypoints.size())
    {
        _keypoints[index].position = position;
        _keypoints[index].forward = forward;
        _keypoints[index].up = up;
        if(!_loadedDistances)
            [self updateDistances];
    }
}

-(void) popKeypoint
{
    _keypoints.pop_back();
    if(!_loadedDistances)
        [self updateDistances];
}

-(void) getKeypoints:(std::vector<simd::float3> &)outKeypoints outForwards:(std::vector<simd::float3> &)outForwards
{
    uint length = (uint) _keypoints.size();
    for (uint i = 0; i < length; i++)
    {
        outKeypoints.push_back(_keypoints[i].position);
        outForwards.push_back(_keypoints[i].forward);
    }
}

-(void) saveKeypointToFile:(NSString*) file
{
    NSString* filename = [NSString stringWithFormat:@"%@/%@.waypoints", getOrCreateApplicationSupportPath(), file];

    NSMutableString *data = [NSMutableString string];

    uint length = (uint)_keypoints.size();
    assert(_distances.size() == length);

    for (uint i = 0; i < length; i++)
    {
        [data appendFormat:@"p %f %f %f\n", _keypoints[i].position.x, _keypoints[i].position.y, _keypoints[i].position.z];
        [data appendFormat:@"f %f %f %f\n", _keypoints[i].forward.x, _keypoints[i].forward.y, _keypoints[i].forward.z];
        [data appendFormat:@"u %f %f %f\n", _keypoints[i].up.x, _keypoints[i].up.y, _keypoints[i].up.z];
        [data appendFormat:@"le %u\n", _keypoints[i].lightEnv];
        [data appendFormat:@"t %f\n", _distances[i]];
        [data appendFormat:@"x\n"];
    }

    [data writeToFile:filename
           atomically:NO
             encoding:NSStringEncodingConversionAllowLossy
                error:nil];

    NSLog(@"Written %d keypoints to %@", length, filename);
}

-(bool) loadKeypointFromFile:(NSString*)file
{
    // Start in app bundle, then look in app support path
    NSURL* url = [[NSBundle mainBundle] URLForResource:file withExtension:@"waypoints"];

    if (!url)
    {
        NSLog(@"Could not find resource '%@'", file);
        return false;
    }

    NSString* filename = url.path;

    NSString* fileContents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];

    NSArray* allLines = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    AAPLCameraKeypoint kp;
    _distances.resize(0);

    for(NSString* line in allLines)
    {
        if([line isEqualToString:@"x"])
        {
            _keypoints.push_back(kp);
            kp = AAPLCameraKeypoint();
        }
        else
        {
            NSArray* ks = [line componentsSeparatedByString:@" "];

            if([ks[0] isEqualToString:@"p"])
            {
                kp.position.x = [ks[1] floatValue];
                kp.position.y = [ks[2] floatValue];
                kp.position.z = [ks[3] floatValue];
            }
            else if([ks[0] isEqualToString:@"f"])
            {
                kp.forward.x = [ks[1] floatValue];
                kp.forward.y = [ks[2] floatValue];
                kp.forward.z = [ks[3] floatValue];
            }
            else if([ks[0] isEqualToString:@"u"])
            {
                kp.up.x = [ks[1] floatValue];
                kp.up.y = [ks[2] floatValue];
                kp.up.z = [ks[3] floatValue];
            }
            else if([ks[0] isEqualToString:@"le"])
            {
                kp.lightEnv = (uint)[ks[1] intValue];
            }
            else if([ks[0] isEqualToString:@"t"])
            {
                float t = [ks[1] floatValue];
                assert(_distances.size() == 0 || t > _distances[_distances.size() - 1]);
                _distances.push_back(t);
            }
        }
    }

    if(_distances.size() == _keypoints.size())
    {
        if(_distances.size())
        {
            _totalDistance = _distances[_distances.size() - 1];
            _loadedDistances = true;
        }
    }
    else
    {
        [self updateDistances];
    }

    return true;
}

@end
