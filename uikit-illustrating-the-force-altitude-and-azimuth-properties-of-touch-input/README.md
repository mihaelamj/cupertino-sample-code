# Illustrating the force, altitude, and azimuth properties of touch input

Capture Apple Pencil and touch input in views.

## Overview

Touch Canvas illustrates responsive handling of Apple Pencil and touch input, focusing on the force, altitude, and azimuth properties of `UITouch`. The sample creates a visualization of force using line thickness, and creates a visualization of altitude and azimuth with an interactive diagram. To build on the concepts demonstrated in this sample and learn about using Apple Pencil and touch input in a drawing app, see [Leveraging touch input for drawing apps][1].

## Calculate the force of a touch

You can use the force of a touch applied by a finger on 3D Touch-enabled devices or from the tip of Apple Pencil to create effects in your app. For example, the force of a touch can change the width of a line on a canvas.

![Diagram of how the sample project visualizes force for line width](Documentation/force.png)

The current force is reported by the [`force`][2] property of [`UITouch`][3].

``` swift
force = touch.force
```

The force value input affects the result of handling a `UITouch`. In this sample, force is interpreted as a value representing the magnitude of a point in a line,  including a lower bound on the force value usable by the app.

``` swift
var magnitude: CGFloat {
    return max(force, 0.025)
}
```

This sample uses the magnitude value to affect drawing on the canvas, including the line width value.

``` swift
context.setLineWidth(point.magnitude)
```

## Create a visualization of Apple Pencil's altitude and azimuth

Touch Canvas contains a visualization of the altitude and azimuth for Apple Pencil as you draw on the screen when the *Debug* mode is enabled.  This visualization is a diagram which continuously updates based on Apple Pencil's motion.

![Diagram of how the sample project visualizes Apple Pencil's altitude and azimuth](Documentation/azimuth-altitude.png)

Apple Pencil reports its altitude as an angle relative to the device surface through the [`altitudeAngle`][4] property on `UITouch`.

``` swift
let altitudeAngle = touch.altitudeAngle
```

In this sample project, the line length extends to the edge of the diagram when Apple Pencil is fully horizontal. If Apple Pencil is perfectly vertical, the line length reduces to a dot under Apple Pencil's tip. The line length calculation transforms the altitude angle relative to the radius of the diagram.

``` swift
/*
 Make the length of the indicator's line representative of the `altitudeAngle`. When the angle is
 zero radians (parallel to the screen surface) the line will be at its longest. At `.pi` / 2 radians,
 only the dot on top of the indicator will be visible directly beneath the touch location.
 */
let altitudeRadius = (1.0 - altitudeAngle / ( CGFloat.pi / 2)) * radius
var lineTransform = CGAffineTransform(scaleX: altitudeRadius, y: 1)
```

Apple Pencil reports its direction, or azimuth, relative to the view Apple Pencil interacts with. A drawing app might use azimuth information to change the shape or strength of a particular drawing tool. Access the azimuth information with the [`azimuthAngle(in:)`][5] and [`azimuthUnitVector(in:)`][6] methods of `UITouch`.

``` swift
let azimuthAngle = touch.azimuthAngle(in: canvasView)
let azimuthUnitVector = touch.azimuthUnitVector(in: canvasView)
```

The interactive diagram demonstrates how altitude, azimuth angle, and azimuth unit vector values can be used together. Here, the azimuth angle rotates around the diagram opposite the actual azimuth value, and the dot at the end of the altitude line moves by combining the altitude and azimuth unit vector properties. A transform efficiently applies the calculated rotation of the line and position of the dot to the diagram so that it remains responsive to small changes in Apple Pencil's position.

``` swift
// Draw the azimuth indicator line as opposite the azimuth by rotating `.pi` radians, for easy visualization.
var rotationTransform = CGAffineTransform(rotationAngle: azimuthAngle)
rotationTransform = rotationTransform.rotated(by: CGFloat.pi)

var dotPositionTransform = CGAffineTransform(translationX: -azimuthUnitVector.dx * altitudeRadius, y: -azimuthUnitVector.dy * altitudeRadius)
dotPositionTransform = dotPositionTransform.concatenating(centeringTransform)
```

## Toggle debug drawing

Touch Canvas contains a debug drawing mode that allows you to view the operation of the properties in detail for different types of input, such as the difference between strokes drawn at different speeds with Apple Pencil. The debug mode enables the interactive diagram for altitude and azimuth, and changes the color of individual line segments to identify if the [`UIEvent`][10] for the line segment included data from [`predictedTouchesForTouch`][9] or [`coalescedTouchesforTouch`][8].

The sample uses the double-tap feature of the second generation Apple Pencil to toggle *Debug* mode when the user configures the preferred double tap action to switch tools. The sample app ignores the other preferred actions. See [Pencil Interactions][7] for more information.

``` swift
func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
    guard UIPencilInteraction.preferredTapAction == .switchPrevious else { return }
    
    /* The tap interaction is a quick way for the user to switch tools within an app.
     Toggling the debug drawing mode from Apple Pencil is a discoverable action, as the button
     for debug mode is on screen and visually changes to indicate what the tap interaction did.
     */
    toggleDebugDrawing(sender: debugButton)
}
```
 
[1]: https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/leveraging_touch_input_for_drawing_apps
[2]: https://developer.apple.com/documentation/uikit/uitouch/force
[3]: https://developer.apple.com/documentation/uikit/uitouch
[4]: https://developer.apple.com/documentation/uikit/uitouch/altitudeangle
[5]: https://developer.apple.com/documentation/uikit/uitouch/azimuthAngle(in:)
[6]: https://developer.apple.com/documentation/uikit/uitouch/azimuthUnitVector(in:)
[7]: https://developer.apple.com/documentation/uikit/pencil_interactions
[8]: https://developer.apple.com/documentation/uikit/uievent/coalescedTouches(for:)
[9]: https://developer.apple.com/documentation/uikit/uievent/predictedTouches(for:)
[10]: https://developer.apple.com/documentation/uikit/uievent
