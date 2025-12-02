/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Class extension methods that manage color and view helper functions.
*/
import SwiftUI

extension Color {
    static var cornflowerBlue: Color { Color(red: 100.0 / 255.0, green: 149.0 / 255.0, blue: 237.0 / 255.0) }
}

extension View {
    var customBorderWidth: Double { 2.0 }
}
