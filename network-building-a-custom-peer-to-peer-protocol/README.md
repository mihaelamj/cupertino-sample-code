# Building a custom peer-to-peer protocol

Use networking frameworks to create a custom protocol for playing a game across iOS, iPadOS, watchOS, and tvOS devices.

## Overview

This TicTacToe sample code project creates a networked game that you can play between different devices, communicating with a custom protocol. The game offers two ways to play:

* On Apple TV, the game uses [DeviceDiscoveryUI](https://developer.apple.com/documentation/devicediscoveryui) to discover nearby iOS, iPadOS, and watchOS devices. After connecting, you can use your device to play against an AI opponent on Apple TV.

* On iOS and iPadOS devices, the game uses Bonjour and TLS to establish secure connections between nearby devices. You can use this mode to play a peer-to-peer two-player game.

- Note: This sample code project is associated with WWDC22 session [110339: Build device-to-device interactions with the Network framework](https://developer.apple.com/wwdc22/110339/). It's also associated with WWDC 2020 session [10110: Support local network privacy in your app](https://developer.apple.com/wwdc20/10110/) and with WWDC 2019 session [713: Advances in Networking, Part 2](https://developer.apple.com/wwdc19/713/).
