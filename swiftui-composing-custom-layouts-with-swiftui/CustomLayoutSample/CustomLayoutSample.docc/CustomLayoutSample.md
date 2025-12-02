# ``CustomLayoutSample``

An app that demonstrates how to arrange views using layout tools that SwiftUI
provides.

## Overview

This sample app demonstrates many of the layout tools that SwiftUI provides by
building an interface that enables people to vote for their favorite kind of
pet. The app offers buttons to vote for a specific pet type, and displays the
vote counts and relative rankings of the various contenders on a leaderboard.
It also shows avatars for the pets, arranged in a way that reflects the current
rankings.

![An iPhone showing the layout of the app, with the three main sections called
out. The group of avatars are in a circular arrangement at the top. The
leaderboard grid is in the middle. The equal-width voting buttons are at the
bottom.](overview)

> Note: This sample code project is associated with WWDC22 session
  [10056: Compose custom layouts with SwiftUI](https://developer.apple.com/wwdc22/10056/).

## Topics

### Leaderboard

- ``Leaderboard``

### Voting buttons

- ``ButtonStack``
- ``MyEqualWidthHStack``
- ``MyEqualWidthVStack``

### Avatars

- ``Profile``
- ``MyRadialLayout``
- ``Avatar``
- ``Podium``

### Data

- ``Model``
- ``Pet``

### App support

- ``CustomLayoutSampleApp``
- ``ContentView``

### Preview providers

- ``Avatar_Previews``
- ``ButtonStack_Previews``
- ``ContentView_Previews``
- ``Leaderboard_Previews``
- ``Podium_Previews``
- ``Profile_Previews``
