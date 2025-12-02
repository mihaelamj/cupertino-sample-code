/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constants for colors and fonts used in the app.
*/

import SwiftUI

extension Color {
    // Rainbow colors
    static let rainbowBlue: Color = Color("RainbowBlue", bundle: .main)
    static let rainbowGraphite: Color = Color("RainbowGraphite", bundle: .main)
    static let rainbowOrange: Color = Color("RainbowOrange", bundle: .main)
    static let rainbowPacificBlue: Color = Color("RainbowPacificBlue", bundle: .main)
    static let rainbowPurple: Color = Color("RainbowPurple", bundle: .main)
    static let rainbowRed: Color = Color("RainbowRed", bundle: .main)
    static let rainbowSilver: Color = Color("RainbowSilver", bundle: .main)
    static let rainbowTeal: Color = Color("RainbowTeal", bundle: .main)
    static let rainbowYellow: Color = Color("RainbowYellow", bundle: .main)
    // Background colors
    static let backgroundBlue: Color = Color("BackgroundBlue", bundle: .main)
    static let backgroundGreen: Color = Color("BackgroundGreen", bundle: .main)
    static let backgroundOrange: Color = Color("BackgroundOrange", bundle: .main)
    static let backgroundYellow: Color = Color("BackgroundYellow", bundle: .main)
}

extension Font {
    static let slogan: Font = .system(size: 40, weight: .bold)
    static let cardTitle: Font = .system(size: 15, weight: .bold)
    static let cardIcon: Font = .system(size: 80, weight: .bold)
}
