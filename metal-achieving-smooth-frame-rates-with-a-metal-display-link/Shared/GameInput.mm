/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the cross-platform game input.
*/

#import <QuartzCore/QuartzCore.h>
#import <GameController/GameController.h>
#import <unordered_map>
#import "MathUtilities.h"
#import "GameInput.h"

static const int NumKeyCodes = 1024;
static const int NumMouseButtons = 16;
static const int GamepadInvalidIndex = 0;

/// Returns a two-dimensional vector that ignores the center radius while normalizing the output range from zero to one.
simd_float2 ignore_dead_space(simd_float2 point, double innerRadiusToIgnore);

/// Resets the state of the class when a game controller isn't connected.
void GamepadState::controllerDidDisconnect()
{
    hasDirectionPad = false;
    hasLeftThumbstick = false;
    hasRightThumbstick = false;
    hasAButton = false;
    hasBButton = false;
    hasXButton = false;
    hasYButton = false;
    useInputSubset = false;
    directionPad = simd_make_float2(0.0, 0.0);
    leftThumbstick = simd_make_float2(0.0, 0.0);
    rightThumbstick = simd_make_float2(0.0, 0.0);
    buttonA = 0.0;
    buttonB = 0.0;
    buttonX = 0.0;
    buttonY = 0.0;
    index = GamepadInvalidIndex;
    controller = nil;
    controllerProfile = nil;
}

/// Searches the list of element keys for a micro and extended gamepad.
void GamepadState::setElementsPresent(NSArray<NSString*> *elementKeys)
{
    hasAButton = [elementKeys containsObject:GCInputButtonA];
    hasBButton = [elementKeys containsObject:GCInputButtonB];
    hasXButton = [elementKeys containsObject:GCInputButtonX];
    hasYButton = [elementKeys containsObject:GCInputButtonY];
    hasDirectionPad = [elementKeys containsObject:GCInputDirectionPad];
    hasLeftThumbstick = [elementKeys containsObject:GCInputLeftThumbstick];
    hasRightThumbstick = [elementKeys containsObject:GCInputRightThumbstick];

    // Use a limited subset of controls if the gamepad doesn't have one or more of the following controls.
    // For example, a micro gamepad only has an A button, an X button, and a D-pad.
    if (!hasLeftThumbstick || !hasRightThumbstick)
    {
        useInputSubset = true;
    }
}

/// Sets a newly connected game controller and queries its elements to determine the available buttons and axes.
bool GamepadState::controllerDidConnect(GCController *gameController, int controllerIndex)
{
    index = controllerIndex;
    controller = gameController;
    controllerProfile = gameController ? gameController.physicalInputProfile : nil;

    NSDictionary<NSString *, GCDeviceElement *> *elements = controllerProfile ? controllerProfile.elements : nil;
    if (!elements)
    {
        return false;
    }

    setElementsPresent(elements.allKeys);
    return true;
}

/// Gets the values for the buttons and axes of a game controller and returns false if the controller isn't connected.
bool GamepadState::poll()
{
    if (controller == nil || index == 0)
    {
        return false;
    }

    GCPhysicalInputProfile *profile = controllerProfile;
    if (!profile)
    {
        return false;
    }

    buttonA = hasAButton ? [profile.buttons objectForKey:GCInputButtonA].value : 0.0f;
    buttonB = hasBButton ? [profile.buttons objectForKey:GCInputButtonB].value : 0.0f;
    buttonX = hasXButton ? [profile.buttons objectForKey:GCInputButtonX].value : 0.0f;
    buttonY = hasYButton ? [profile.buttons objectForKey:GCInputButtonY].value : 0.0f;

    if (hasLeftThumbstick)
    {
        GCControllerDirectionPad *thumbstick = [profile.dpads objectForKey:GCInputLeftThumbstick];
        float dx = thumbstick.xAxis.value;
        float dy = thumbstick.yAxis.value;
        leftThumbstick = simd_make_float2(dx, dy);
    }

    if (hasRightThumbstick)
    {
        GCControllerDirectionPad *thumbstick = [profile.dpads objectForKey:GCInputRightThumbstick];
        float dx = thumbstick.xAxis.value;
        float dy = thumbstick.yAxis.value;
        rightThumbstick = simd_make_float2(dx, dy);
    }

    if (hasDirectionPad)
    {
        GCControllerDirectionPad *dpad = [profile.dpads objectForKey:GCInputDirectionPad];
        float dx = (dpad.right.value > 0.25 ? 1.0 : 0.0) + (dpad.left.value > 0.35 ? -1.0 : 0.0);
        float dy = (dpad.up.value > 0.25 ? 1.0 : 0.0) + (dpad.down.value > 0.25 ? -1.0 : 0.0);
        simd_float2 dpadXY = directionPad;
        simd_float2 dxdy = simd_make_float2(dx, dy);
        directionPad = accelerateClamp2(dpadXY, 0.025, dxdy, -1.0, 1.0);
    }
    else
    {
        directionPad = leftThumbstick;
    }

    return true;
}

/// The platform-independent game input class implementation.
@implementation GameInput
{
    float _keys[NumKeyCodes];
    float _mouseButtons[NumMouseButtons];

    /// A counter that provides indexes for connected game controllers.
    int _controllerIndexCount;
    /// The most recent game controller that was the current one, or nil if none was.
    GCController *_currentGamepadController;
    /// A hash table that maps a controller to its gamepad state object index.
    std::unordered_map<void *, int> _controllersMap;
    /// A hash table that maps an index to a gamepad state object for all connected controllers.
    std::unordered_map<int, GamepadState> _gamepads;
    /// A default game controller state object to use when a gamepad isn't connected.
    GamepadState _defaultGamepad;
    /// An index to the most recently used gamepad.
    int _currentGamepadIndex;
    /// The game controller state for systems that allow a keyboard and mouse.
    GamepadState _keyboardMouseGamepadState;
    
    int _numKeyboardsConnected;
    int _numMiceConnected;
    int _numGameControllersConnected;

    /// The current dimensions of the drawable in the window to make decisions about the virtual controller or mouse coordinates.
    CGSize _drawableSize;

#if TARGET_OS_IOS
    /// The virtual controller object for apps that support it.
    GCVirtualController *_virtualControllerObject;
#else
    NSObject *_virtualControllerObject;
#endif
    /// A flag that indicates whether the app should and can use a virtual controller.
    bool _appAllowsVirtualController;
    /// A flag that reflects whether the app's currently using a virtual controller.
    bool _isUsingVirtualController;
}

/// Adds the controller connection and disconnection notifications and sets up a virtual controller if a controller isn't connected.
- (nonnull instancetype)init
{
    for (int i = 0; i < NumKeyCodes; i++)
    {
        _keys[i] = 0.0f;
    }

    for (int i = 0; i < NumMouseButtons; i++)
    {
        _mouseButtons[i] = 0.0f;
    }

    _numKeyboardsConnected = 0;
    _numMiceConnected = 0;
    _numGameControllersConnected = 0;

    // Don't use the virtual controller if running on a Mac.
    _appAllowsVirtualController = !NSProcessInfo.processInfo.isMacCatalystApp && !NSProcessInfo.processInfo.isiOSAppOnMac;

    [self addObservers];
    return self;
}

/// Adds the notification observers for the supported platform devices.
- (void)addObservers
{
    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    [defaultCenter addObserver:self
                      selector:@selector(controllerDidConnect:)
                          name:GCControllerDidConnectNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(controllerDidDisconnect:)
                          name:GCControllerDidDisconnectNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(mouseDidConnect:)
                          name:GCMouseDidConnectNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(mouseDidDisconnect:)
                          name:GCMouseDidDisconnectNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(keyboardDidConnect:)
                          name:GCKeyboardDidConnectNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(keyboardDidDisconnect:)
                          name:GCKeyboardDidDisconnectNotification
                        object:nil];
}

/// Updates the current time and retrieves the current game input state.
- (void)poll
{
    // Check whether the current game controller has changed.
    GCController *current = GCController.current;
    if (current)
    {
        if (current != _currentGamepadController)
        {
            _currentGamepadController = current;
            void *key = (__bridge void *)(current);
            if (!_controllersMap.count(key))
            {
                _currentGamepadIndex = GamepadInvalidIndex;
            }
            else
            {
                _currentGamepadIndex = _controllersMap[key];
            }
        }
    }

    // Update all the connected gamepads.
    for (auto& gamepad: _gamepads)
    {
        gamepad.second.poll();
    }

#if TARGET_OS_IOS
    if (self.shouldNotUseVirtualController)
    {
        [self stopUsingVirtualController];
    }
    else if (![self controllerConnected])
    {
        [self setupVirtualController];
    }
#endif

    [self updateWithKeyboardMouse];
}

/// Records the drawable size to determine input decisions like disabling the virtual controller.
- (void)drawableSizeDidChange:(CGSize)size
{
    _drawableSize = size;
}

/// Returns the state object for the most recently connected gamepad, or the default one if a controller isn't connected.
- (GamepadState&)currentGamepad
{
    if (_currentGamepadIndex != GamepadInvalidIndex)
    {
        if (!_gamepads.count(_currentGamepadIndex))
        {
            return _defaultGamepad;
        }
        return _gamepads[_currentGamepadIndex];
    }

    if ([self keyboardAndMouseConnected])
    {
        return _keyboardMouseGamepadState;
    }

    return _defaultGamepad;
}

/// Adds a game controller to the gamepads list and creates a lookup index for it.
- (void)addConnectedGamepad:(GCController *)controller
{
    _controllerIndexCount += 1;
    int index = _controllerIndexCount;
    GamepadState gamepadState;
    gamepadState.controllerDidConnect(controller, index);
    _gamepads[index] = gamepadState;
    void *key = (__bridge void *)(controller);
    _controllersMap[key] = index;
    _currentGamepadIndex = index;
    _numGameControllersConnected += 1;
    NSLog(@"Added gamepad %@.", @(index));
}

/// Removes a disconnected gamepad from the gamepad state object collection.
- (void)removeDisconnectedGamepad:(GCController *)controller
{
    if (!controller)
    {
        return;
    }

    // Find the index to the controller and remove the gamepad state object.
    // If there's an index that references this controller, reset it to `GamepadInvalidIndex`.
    void *key = (__bridge void *)(controller);
    if (_controllersMap.count(key))
    {
        int index = _controllersMap[key];
        _gamepads.erase(index);
        _controllersMap.erase(key);

        // Invalidate the current gamepad index if it's the controller that's disconnected.
        if (_currentGamepadIndex == index)
        {
            _currentGamepadIndex = GamepadInvalidIndex;
        }
        _numGameControllersConnected -= 1;
        NSLog(@"Removed gamepad %@.", @(index));
    }
}

/// Updates the keyboard and mouse gamepad state with the arrow keys.
- (BOOL)updateWithKeyboardMouse
{
    GamepadState &state = _keyboardMouseGamepadState;
    float dx = differential([self keyPressed:GCKeyCodeRightArrow], [self keyPressed:GCKeyCodeLeftArrow]);
    float dy = differential([self keyPressed:GCKeyCodeUpArrow], [self keyPressed:GCKeyCodeDownArrow]);
    simd_float2 dpadXY = state.directionPad;
    simd_float2 dxdy = simd_make_float2(dx, dy);
    state.directionPad = accelerateClamp2(dpadXY, 0.025, dxdy, -1.0, 1.0);

    return true;
}

/// MARK: - Keyboard, mouse, and gamepad update code.

/// Sets the current key state for a key code.
- (void)setKeyPressed:(GCKeyCode)keyCode value:(float)value
{
    int k = (int)keyCode;
    if (k < 0 || k >= NumKeyCodes)
    {
        return;
    }
    _keys[k] = value;
}

/// Returns the current key state for a key code.
- (float)keyPressed:(GCKeyCode)keyCode
{
    int k = (int)keyCode;
    if (k < 0 || k >= NumKeyCodes)
    {
        return 0.0f;
    }
    return _keys[k];
}

/// Sets the current pressed state of a mouse button.
- (void)setMouseButtonPressed:(int)buttonIndex value:(float)value
{
    if (buttonIndex < 0 || buttonIndex >= NumMouseButtons)
    {
        return;
    }
    _mouseButtons[buttonIndex] = value;
}

/// Returns the current pressed state of a mouse button.
- (float)mouseButtonPressed:(int)buttonIndex
{
    if (buttonIndex < 0 || buttonIndex >= NumMouseButtons)
    {
        return 0.0f;
    }
    return _mouseButtons[buttonIndex];
}

/// Returns the array of key-pressed values.
- (nonnull float *)keys
{
    return _keys;
}

/// Returns the array of mouse button values.
- (nonnull float *)mouseButtons
{
    return _mouseButtons;
}

// MARK: - Keyboard, mouse, and gamepad connection code.

/// Returns true if a keyboard is connected.
- (bool)keyboardConnected
{
    return _numKeyboardsConnected > 0;
}

/// Returns true if a mouse and a keyboard are connected.
- (bool)keyboardAndMouseConnected
{
    return _numKeyboardsConnected > 0 && _numMiceConnected > 0;
}

/// Returns true if a mouse is connected.
- (bool)mouseConnected
{
    return _numMiceConnected > 0;
}

/// Returns true if a game controller is connected.
- (bool)controllerConnected;
{
    return _numGameControllersConnected > 0;
}

/// Tells the game input class when a keyboard connects.
- (void)keyboardDidConnect:(NSNotification *)notification
{
    GCKeyboard *keyboard = (GCKeyboard *)notification.object;
    if (!keyboard)
    {
        return;
    }

    _keyboardMouseGamepadState.setElementsPresent(@[GCInputButtonA, GCInputButtonX, GCInputDirectionPad]);

    __block GameInput *weakSelf = self;
    keyboard.keyboardInput.keyChangedHandler = ^(GCKeyboardInput *keyboard, GCControllerButtonInput *key, GCKeyCode keyCode, BOOL pressed) {
        GameInput *strongSelf = weakSelf;
        if (strongSelf == nil)
        {
            return;
        }

        float value = pressed ? 1.0f : 0.0f;
        [strongSelf setKeyPressed:keyCode value:value];
    };
    
    _numKeyboardsConnected += 1;
}

/// Tells the game input class when a keyboard disconnects.
- (void)keyboardDidDisconnect:(NSNotification *)notification
{
    _numKeyboardsConnected -= 1;
}

/// Tells the game input class when a mouse connects.
- (void)mouseDidConnect:(NSNotification *)notification
{
    GCMouse *mouse = (GCMouse *)notification.object;
    if (mouse == nil)
    {
        return;
    }

    GCMouseInput *mouseInput = mouse.mouseInput;
    if (mouseInput == nil)
    {
        return;
    }

    __block GameInput *weakSelf = self;
    mouseInput.mouseMovedHandler = ^(GCMouseInput *mouse, float deltaX, float deltaY) {
        GameInput *strongSelf = weakSelf;
        if (strongSelf == nil)
        {
            return;
        }

        strongSelf.mouseDelta = simd_make_float2(deltaX, deltaY);
    };

    mouseInput.leftButton.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        GameInput *strongSelf = weakSelf;
        if (strongSelf == nil)
        {
            return;
        }

        float buttonValue = pressed ? 1.0f : 0.0f;
        [strongSelf setMouseButtonPressed:0 value:buttonValue];
    };

    mouseInput.rightButton.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        GameInput *strongSelf = weakSelf;
        if (strongSelf == nil)
        {
            return;
        }

        float buttonValue = pressed ? 1.0f : 0.0f;
        [strongSelf setMouseButtonPressed:1 value:buttonValue];
    };
    
    _numMiceConnected += 1;
}

/// Tells the game input class when a mouse disconnects.
- (void)mouseDidDisconnect:(NSNotification *)notification
{
    _numMiceConnected -= 1;
}

/// Tells the game input class when a game controller connects.
- (void)controllerDidConnect:(NSNotification *)notification
{
    GCController *controller = (GCController *)notification.object;
    if (!controller)
    {
        return;
    }
    [self addConnectedGamepad:controller];
}

/// Tells the game input class when a game controller disconnects.
- (void)controllerDidDisconnect:(NSNotification *)notification
{
    GCController *controller = (GCController *)notification.object;
    if (!controller)
    {
        return;
    }
    [self removeDisconnectedGamepad:controller];
}

// MARK: - Helper functions to use a virtual controller.

/// Checks whether the app shouldn't use a virtual controller.
- (BOOL)shouldNotUseVirtualController
{
    // Don't use it if the flag at the app's launch disallows it.
    if (!_appAllowsVirtualController)
    {
        return true;
    }
    // Don't use it if the drawable isn't in landscape mode.
    if (_drawableSize.width == 0 || _drawableSize.height == 0 || _drawableSize.width <= _drawableSize.height)
    {
        return true;
    }
    // Stop using it if a physical controller is connected.
    if (_isUsingVirtualController && _numGameControllersConnected > 1)
    {
        return true;
    }
    return false;
}

/// Releases the virtual controller object to stop the virtual controller.
- (void)stopUsingVirtualController
{
#if TARGET_OS_IOS
    if (!_isUsingVirtualController)
    {
        return;
    }
    _isUsingVirtualController = false;
    _virtualControllerObject = nil;
#endif
}

/// Starts a virtual controller if it's not already created.
- (void)setupVirtualController
{
#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
    if (@available(iOS 15.0, *))
    {
        if (_virtualControllerObject != nil)
        {
            return;
        }
        
        if (self.shouldNotUseVirtualController)
        {
            return;
        }
        
        // Create the virtual controller.
        GCVirtualControllerConfiguration *config = [GCVirtualControllerConfiguration new];
        config.elements = [[NSSet alloc] initWithArray:@[ GCInputLeftThumbstick, GCInputRightThumbstick, GCInputButtonA, GCInputButtonX ]];
        _virtualControllerObject = [GCVirtualController virtualControllerWithConfiguration:config];
        _isUsingVirtualController = true;
        [_virtualControllerObject connectWithReplyHandler:^(NSError * _Nullable error) {
            NSError *e = error;
            if (e != nil)
            {
                NSLog(@"There's an error creating the virtual controller: %@", e.localizedDescription);
            }
        }];
    }
#endif
}
@end
