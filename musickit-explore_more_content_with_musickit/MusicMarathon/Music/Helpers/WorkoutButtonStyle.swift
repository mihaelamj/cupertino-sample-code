/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button style the workout button uses.
*/

import SwiftUI

// MARK: - Workout button style

/// A custom button style that encapsulates the common modifiers for the workout buttons in the user interface.
struct WorkoutButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .background(.purple)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? Self.maxScaleEffect : 1)
            .animation(.easeOut(duration: Self.animationEase), value: configuration.isPressed)
    }
    
    // MARK: - Constants
    
    private static let maxScaleEffect: CGFloat = 1.2
    private static let animationEase: CGFloat = 0.2
}

// MARK: - Button style extension

extension ButtonStyle where Self == WorkoutButtonStyle {
    
    /// A button style that encapsulates the common modifiers for workout buttons shown in the user interface.
    static var workout: WorkoutButtonStyle {
        WorkoutButtonStyle()
    }
}
