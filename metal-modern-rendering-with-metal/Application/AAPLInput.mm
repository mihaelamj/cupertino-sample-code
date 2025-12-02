/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implentation of type and utility functions used to control input.
*/

#import "AAPLInput.h"

#import <simd/simd.h>

@implementation AAPLTouch
@end

void processStateChanges(uint numStateToggles, const AAPLStateToggle* stateToggles,
                         uint numStateCycles, const AAPLStateCycle* stateCycles,
                         uint numStateCyclesFloat, const AAPLStateCycleFloat* stateCyclesFloat,
                         NSSet<NSNumber*>* justDownKeys)
{
    for(int i = 0; i < numStateToggles; i++)
    {
        bool& val = *stateToggles[i].state;

        if([justDownKeys containsObject: @(stateToggles[i].key)])
            val = !val;
    }

    for(int i = 0; i < numStateCycles; i++)
    {
        uint& val = *stateCycles[i].state;

        if([justDownKeys containsObject: @(stateCycles[i].forwardKey)])
            val = (val + 1) % stateCycles[i].max; // Cycle forward.

        if(stateCycles[i].backKey != -1 && [justDownKeys containsObject: @(stateCycles[i].backKey)])
            val = (val + stateCycles[i].max - 1) % stateCycles[i].max; // Cycle backward.
    }

    for(int i = 0; i < numStateCyclesFloat; i++)
    {
        const AAPLStateCycleFloat& state = stateCyclesFloat[i];

        float& val = *state.state;

        if([justDownKeys containsObject: @(state.forwardKey)])
            val = fmodf(val + state.step, state.max); // Cycle forward.

        if(stateCyclesFloat[i].backKey != -1 && [justDownKeys containsObject: @(state.backKey)])
            val = fmodf(val + state.max - state.step, state.max); // Cycle backward.
    }
}

// Update current input state for this frame.
void AAPLInput::initialize()
{
    pressedKeys  = [NSMutableSet set];
    justDownKeys = [NSMutableSet set];
    touches      = [NSMutableArray array];
}

// Update current input state for this frame.
void AAPLInput::update()
{
    // -------------------
    // Update Input
    // -------------------
#if MOUSE_SIMULATE_TOUCH
    if(mouseDown)
    {
        AAPLTouch* mouseTouch   = [AAPLTouch new];
        mouseTouch.pos          = simd::make_float2(mouseCurrentPos.x, mouseCurrentPos.y);
        mouseTouch.startPos     = simd::make_float2(mouseDownPos.x, mouseDownPos.y);
        mouseTouch.delta        = simd::make_float2(mouseDeltaX, mouseDeltaY);

        [touches addObject:mouseTouch];
    }

    mouseDeltaX = 0.0f;
    mouseDeltaY = 0.0f;
#endif

#if USE_VIRTUAL_JOYSTICKS
    const float MAX_JOYSTICK_DIST = 0.1f;

    virtualJoysticks[0].deadzoneRadius   = 0.01f;
    virtualJoysticks[0].value_x          = 0.0f;
    virtualJoysticks[0].value_y          = 0.0f;

    virtualJoysticks[0].pos      = simd::make_float2(0.2f, 0.8f);
    virtualJoysticks[0].radius   = 0.1f;
#endif // USE_VIRTUAL_JOYSTICKS

    for(AAPLTouch* touch in touches)
    {
        bool used = false;
#if USE_VIRTUAL_JOYSTICKS
        for(int i = 0; i < NUM_VIRTUAL_JOYSTICKS; ++i)
        {
            simd::float2 downOffset = touch.startPos - virtualJoysticks[i].pos;
            float downDist          = simd_length(downOffset);

            if(downDist > virtualJoysticks[i].radius)
                continue; // didnt press joystick

            virtualJoysticks[i].pos = touch.startPos;

            simd::float2 offset = touch.pos - virtualJoysticks[i].pos;

            float dist = MAX(simd_length(offset), 0.001f);

            offset = offset/dist * MIN(MAX(0.0f, dist - virtualJoysticks[i].deadzoneRadius), MAX_JOYSTICK_DIST);

            virtualJoysticks[i].pos      += offset;
            virtualJoysticks[i].value_x  = offset.x / MAX_JOYSTICK_DIST;
            virtualJoysticks[i].value_y  = -offset.y / MAX_JOYSTICK_DIST;

            used = true;
        }
#endif // USE_VIRTUAL_JOYSTICKS

        if(used)
            continue;

        mouseDeltaX = touch.delta.x;
        mouseDeltaY = touch.delta.y;
    }
}

// Clear current input.
void AAPLInput::clear()
{
    mouseDeltaX = 0.0f;
    mouseDeltaY = 0.0f;

    [justDownKeys removeAllObjects];
    [touches removeAllObjects];
}
