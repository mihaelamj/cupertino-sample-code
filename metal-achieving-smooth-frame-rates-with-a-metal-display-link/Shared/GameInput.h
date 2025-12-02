/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the cross-platform game input.
*/

#pragma once

#import <TargetConditionals.h>
#import <Foundation/Foundation.h>
#import <GameController/GameController.h>
#import <simd/simd.h>
#import "MathUtilities.h"

class GamepadState {
public:
    int index{0};
    GCController * _Nullable controller{nil};
    GCPhysicalInputProfile * _Nullable controllerProfile{nil};
    bool hasDirectionPad{false};
    bool hasLeftThumbstick{false};
    bool hasRightThumbstick{false};
    bool hasAButton{false};
    bool hasBButton{false};
    bool hasXButton{false};
    bool hasYButton{false};
    bool useInputSubset{false};
    bool ignoreInnerRadius{false};
    simd_float2 directionPad{0.0, 0.0};
    simd_float2 leftThumbstick{0.0, 0.0};
    simd_float2 rightThumbstick{0.0, 0.0};
    float buttonA{0.0};
    float buttonB{0.0};
    float buttonX{0.0};
    float buttonY{0.0};

    void controllerDidDisconnect();
    void setElementsPresent(NSArray<NSString*> * _Nonnull elementKeys);
    bool controllerDidConnect(GCController * _Nonnull gameController, int controllerIndex);
    bool poll();
};

/// The platform-independent game input class.
@interface GameInput : NSObject

- (nonnull instancetype)init;

/// Adds the notification observers for the supported platform devices.
- (void)addObservers;

/// Updates the current time and retrieves the current game input state.
- (void)poll;

/// Records the drawable size to determine input decisions like disabling the virtual controller.
- (void)drawableSizeDidChange:(CGSize)size;

/// Returns the state object for the most recently connected gamepad, or the default one if a controller isn't connected.
- (GamepadState&)currentGamepad;

/// Sets the current key state for a key code.
- (void)setKeyPressed:(GCKeyCode)keyCode value:(float)value;

/// Returns the current key state for a key code.
- (float)keyPressed:(GCKeyCode)keyCode;

/// Sets the current state of a mouse button.
- (void)setMouseButtonPressed:(int)buttonIndex value:(float)value;

/// Returns the current pressed state for a mouse button.
- (float)mouseButtonPressed:(int)buttonIndex;

/// Returns true if a keyboard is connected.
- (bool)keyboardConnected;

/// Returns true if both a keyboard and mouse are connected.
- (bool)keyboardAndMouseConnected;

/// Returns true if a mouse is connected.
- (bool)mouseConnected;

/// Returns true if a gamepad is connected.
- (bool)controllerConnected;

/// Tells the game input class when a keyboard connects.
- (void)keyboardDidConnect:(nullable NSNotification *)notification;

/// Tells the game input class when a keyboard disconnects.
- (void)keyboardDidDisconnect:(nullable NSNotification *)notification;

/// Tells the game input class when a mouse connects.
- (void)mouseDidConnect:(nullable NSNotification *)notification;

/// Tells the game input class when a mouse disconnects.
- (void)mouseDidDisconnect:(nullable NSNotification *)notification;

/// Tells the game input class when a game controller connects.
- (void)controllerDidConnect:(nullable NSNotification *)notification;

/// Tells the game input class when a game controller disconnects.
- (void)controllerDidDisconnect:(nullable NSNotification *)notification;

/// An array that stores whether a keyboard key is in a pressed state.
@property (nonatomic, readonly, nonnull) float *keys;

/// An array that stores whether a mouse button is in a pressed state.
@property (nonatomic, readonly, nonnull) float *mouseButtons;

/// A 2D vector that stores the most recent mouse position delta.
@property (nonatomic) simd_float2 mouseDelta;

@end

// MARK: - Helper functions to smooth game input variables.

/// Takes a positive and negative input with values 0 to 1 and returns -1, 0, or 1.
static inline
float differential(float positiveInput, float negativeInput)
{
    float result = 0.0f;
    if (positiveInput > 0.0f)
    {
        result += 1.0f;
    }
    if (negativeInput > 0.0f)
    {
        result -= 1.0f;
    }
    return result;
}

/// Uses the input to increase or decrease the current value within the specified limits [a, b].
static inline
float accelerateClamp(float currentValue, float speed, float input, float a, float b)
{
    return fclamp(currentValue + speed * input, a, b);
}

/// Uses the input to increase or decrease the current value within the specified limits [a, b].
static inline
simd_float2 accelerateClamp2(simd_float2 xy, float speed, simd_float2 dxdy, float a, float b)
{
    return simd_make_float2(accelerateClamp(xy.x, speed, dxdy.x, a, b),
                            accelerateClamp(xy.y, speed, dxdy.y, a, b));
}


/// Ramps the current value up or down at a set speed within the specified limits [a, b].
static inline
float rampClamp(float currentValue, float speed, float input, float a, float b)
{
    if (input > 0.0f)
    {
        return fclamp(currentValue + speed, a, b);
    }
    else
    {
        return fclamp(currentValue - speed, a, b);
    }
}

/// Ignores the inner radius of a game thumbstick input to avoid drift or jerkiness.
static inline
simd_float2 ignoreInnerRadius(simd_float2 point, double innerRadiusToIgnore)
{
    // Check if `point` is inside the inner radius.
    double r = ABS(simd_length(point));
    if (r < innerRadiusToIgnore)
        return simd_make_float2(0, 0);
    // Calculate the normalized vector direction.
    double cos_theta = point.x / r;
    double sin_theta = point.y / r;
    // Remap the radius back to the zero-to-one normalized range.
    r = (r - innerRadiusToIgnore) / (1.0 - innerRadiusToIgnore);
    return simd_make_float2(r * cos_theta, r * sin_theta);
}
