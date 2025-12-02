/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the cross-platform game state.
*/

#import <QuartzCore/QuartzCore.h>
#import "MathUtilities.h"
#import "GameState.h"

@implementation GameState
{
    float _inputA;
    float _inputX;
}

- (instancetype)init
{
    _deltaTime = 0.0;
    
    _rotationSpeed = 1.0;
    
    _inputA = 0.0f;
    _inputX = 0.0f;
    
    _gameInput = [GameInput new];
    
    return self;
}

- (void)update:(CFTimeInterval)delta
{
    _deltaTime = delta;
    
    GameInput *input = _gameInput;
    if (input != nil) {
        [input poll];
    }
    [self smoothInputs];
    [self updateRotationSpeed];
}

/// Constructs a view matrix based on the current input state.
- (simd_float4x4)viewMatrix
{
    if (!_gameInput) {
        return matrix4x4_identity();
    }
    
    // Ignore the right thumbstick when it's close to its center position to improve the input smoothness.
    GamepadState &gamepad = _gameInput.currentGamepad;
    simd_float2 rightXY = gamepad.rightThumbstick;
    if (gamepad.ignoreInnerRadius) {
        rightXY = ignoreInnerRadius(rightXY, 0.25);
    }
    
    /// A translation matrix that positions the camera several units away and adds a zoom factor from the gamepad.
    simd_float4x4 Tz = matrix4x4_translation(3.0 * rightXY.x, 0.0, -6.0 - 3.0 * rightXY.y);
    
    // Calculate a turntable matrix that uses a tilt and zoom.
    simd_float4x4 viewMatrix = matrix4x4_identity();
    viewMatrix = simd_mul(viewMatrix, Tz);
    
    return viewMatrix;
}

/// Smooths the inputs coming from the game controller direction pad and the A and X buttons.
- (void)smoothInputs
{
    GamepadState &gamepad = _gameInput.currentGamepad;
    _inputA = rampClamp(_inputA, 0.05, gamepad.buttonA, 0.0, 1.0);
    _inputX = rampClamp(_inputX, 0.05, gamepad.buttonX, 0.0, 1.0);
}

/// Updates the model's rotation speed and ensures the value stays in the -pi to pi range.
- (void)updateRotationSpeed
{
    GamepadState &gamepad = _gameInput.currentGamepad;
    double changeInRotationSpeed = 3.0;
    if (_gameInput.controllerConnected)
    {
        changeInRotationSpeed *= gamepad.leftThumbstick.x;
    }
    else if (_gameInput.mouseConnected)
    {
        changeInRotationSpeed *= differential([_gameInput mouseButtonPressed:0],
                                              [_gameInput mouseButtonPressed:1]);
    }
    else
    {
        changeInRotationSpeed = 0.0;
    }
     
    double inputSpeed = changeInRotationSpeed * _deltaTime;
    _rotationSpeed = dclamp(_rotationSpeed + inputSpeed, -5.0, 5.0);
}

@end
