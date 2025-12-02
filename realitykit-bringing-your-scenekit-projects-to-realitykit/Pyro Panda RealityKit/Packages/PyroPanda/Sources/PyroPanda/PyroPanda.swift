/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The bundle for this Swift package.
*/

import Foundation
import RealityKit

/// The bundle for the `PyroPanda` project.
public let pyroPandaBundle = Bundle.module

@MainActor
public let components: [any Component.Type] = [
    SpinComponent.self,
    RunAwayComponent.self
]
