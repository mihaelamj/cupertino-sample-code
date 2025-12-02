# Building a multidevice workout app

@Available(Xcode, introduced: "15.0")

Mirror a workout from a watchOS app to its companion iOS app, and perform bidirectional communication between them.

## Overview

- Note: This sample code project is associated with WWDC23 session 10023: [Build a multidevice workout app](https://developer.apple.com/wwdc23/10023/).

## Configure the sample code project

This sample code project needs to run on physical devices. Before you run it with Xcode:

* Set the developer team for all targets to let Xcode automatically manage the provisioning profile. For more information, see [Assign a project to a team](https://help.apple.com/xcode/mac/current/#/dev23aab79b4).
* In the Info pane of the `MirroringWorkoutsSample Watch App` target, change the value of the `WKCompanionAppBundleIdentifier` key to the bundle ID of the iOS app.
