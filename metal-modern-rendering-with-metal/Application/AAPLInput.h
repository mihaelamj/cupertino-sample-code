/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for type and utility functions used to control input.
*/

#import <Foundation/Foundation.h>
#import <simd/types.h>

#define MOUSE_SIMULATE_TOUCH    (0 && TARGET_OS_MAC)

#define USE_VIRTUAL_JOYSTICKS   ((1 && TARGET_OS_IPHONE) || (0 && TARGET_OS_MAC))
#define NUM_VIRTUAL_JOYSTICKS   (1)

// Keys used by this demo; the enum values correlate to their key codes in events.h
enum AAPLControls
{
    // translate (keycodes)
    AAPLControlsForward     = 0x0d, // W
    AAPLControlsBackward    = 0x01, // S
    AAPLControlsStrafeUp    = 0x31, // spacebar
    AAPLControlsStrafeDown  = 0x08, // C
    AAPLControlsStrafeLeft  = 0x00, // A
    AAPLControlsStrafeRight = 0x02, // 

    // rotate (keycodes)
    AAPLControlsRollLeft    = 0x0c, // Q
    AAPLControlsRollRight   = 0x0e, // E
    AAPLControlsTurnLeft    = 0x7b, // arrow left
    AAPLControlsTurnRight   = 0x7c, // arrow right
    AAPLControlsTurnUp      = 0x7e, // arrow down
    AAPLControlsTurnDown    = 0x7d, // arrow up

    // additional virtual keys, not linked to a key code; 0x80 and up
    AAPLControlsFast        = 0x80, // Shift
    AAPLControlsSlow        = 0x81, // Control

    AAPLControlsToggleFreezeCulling     = 0x06, // Z
    AAPLControlsControlSecondary        = 0x2F, // .
    AAPLControlsCycleDebugView          = 0x05, // G
    AAPLControlsCycleDebugViewBack      = 0x04, // H
    AAPLControlsToggleLightWireframe    = 0x25, // L
    AAPLControlsCycleLightHeatmap       = 0x28, // K
    AAPLControlsCycleLightEnvironment   = 0x12, // 1
    AAPLControlsCycleLights             = 0x13, // 2
    AAPLControlsCycleScatterScale       = 0x14, // 3
    AAPLControlsToggleTemporalAA        = 0x15, // 4
    AAPLControlsToggleWireframe         = 0x17, // 5
    AAPLControlsToggleOccluders         = 0x16, // 6
    AAPLControlsDebugDrawOccluders      = 0x1A, // 7

#if USE_TEXTURE_STREAMING
    AAPLControlsCycleTextureStreaming   = 0x11, // T
#endif

    AAPLControlsTogglePlayback          = 0x09, // V

    AAPLControlsToggleDebugK            = 0x1D, // 0 - for local debugging only!
};

// Stores information about a touch.
@interface AAPLTouch : NSObject

    @property simd::float2 pos;         // Current position.
    @property simd::float2 startPos;    // Starting position of touch.
    @property simd::float2 delta;       // Offset of touch this frame.

@end

#if USE_VIRTUAL_JOYSTICKS
// Stores the configuration of a virtual joystick.
struct AAPLVirtualJoystick
{
    simd::float2 pos;
    float radius;
    float deadzoneRadius;

    float value_x;
    float value_y;
};
#endif

// Encapsulates all of the inputs to be passed to subsystems.
struct AAPLInput
{
    // Array of keys currently pressed.
    NSMutableSet<NSNumber*>*    pressedKeys;
    // Array of keys pressed this frame.
    NSMutableSet<NSNumber*>*    justDownKeys;
    // Mouse movement this frame.
    float                       mouseDeltaX;
    float                       mouseDeltaY;
    // Flag to indicate that the mouse button was pressed.
    bool                        mouseDown;
    // Location of mouse pointer when the button was pressed.
    simd::float2                mouseDownPos;
    // Location of mouse pointer.
    simd::float2                mouseCurrentPos;

    // Array of touches in progress.
    NSMutableArray<AAPLTouch*>* touches;

#if USE_VIRTUAL_JOYSTICKS
    AAPLVirtualJoystick         virtualJoysticks[NUM_VIRTUAL_JOYSTICKS];
#endif

    void initialize();
    void update();
    void clear();
};

// Stores a pointer to a flag and the key that toggles the flag.
typedef struct
{
    bool*   state;
    char    key;
} AAPLStateToggle;

// Stores a pointer to a state and the keys that cycle the state upto the
//  specified maximum.
typedef struct
{
    uint*   state;
    char    forwardKey;
    char    backKey;
    int     max;
} AAPLStateCycle;

// Stores a pointer to a state and the keys that cycle the state upto the
//  specified maximum, with a fixed step.
typedef struct
{
    float*  state;
    char    forwardKey;
    char    backKey;
    float   max;
    float   step;
} AAPLStateCycleFloat;

// Toggles and cycles states based on the keys pressed during this frame.
void processStateChanges(uint numStateToggles, const AAPLStateToggle* stateToggles,
                         uint numStateCycles, const AAPLStateCycle* stateCycles,
                         uint numStateCyclesFloat, const AAPLStateCycleFloat* stateCyclesFloat,
                         NSSet<NSNumber*>* justDownKeys);
