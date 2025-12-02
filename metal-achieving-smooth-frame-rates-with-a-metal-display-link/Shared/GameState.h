/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the cross-platform game state.
*/

#pragma once

#import <simd/simd.h>
#import "GameInput.h"

@interface GameState : NSObject

- (nonnull instancetype)init;

/// Updates the time variables and processes the game input.
- (void)update:(CFTimeInterval)delta;

/// Constructs a view matrix based on the current input state.
- (simd_float4x4)viewMatrix;

/// Updates the model's rotation speed and ensures the value stays in the -pi to pi range.
- (void)updateRotationSpeed;

@property (nonatomic) double deltaTime;

@property (nonatomic) double rotationSpeed;

@property (nonatomic, nonnull) GameInput *gameInput;

@end
