# Building peer-to-peer apps

Communicate with nearby devices over a secure, high-throughput, low-latency connection by using Wi-Fi Aware.

## Overview

This sample app uses the Wi-Fi Aware framework to build a peer-to-peer app. One device acts as a publisher by running a local simulation and advertising a service. Nearby devices connect to the publisher and subscribe to the simulation movements. The Wi-Fi Aware framework provides a secure, low-latency connection between the publisher and connected devices.

The sample app shows the interactions between the publisher and subscriber devices. The publisher simulates a satellite orbiting a planet. It sends the satellite’s coordinates to connected subscriber devices. The subscribers receive the coordinates for each frame on the publisher simulation and update their local satellite’s position, mirroring the publisher's.

For more details see [Building peer-to-peer apps](https://developer.apple.com/documentation/wifiaware/building-peer-to-peer-apps).
