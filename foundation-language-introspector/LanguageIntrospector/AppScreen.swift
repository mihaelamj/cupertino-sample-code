/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines information for the active screen.
*/

import SwiftUI

enum AppScreen: Codable, Hashable, Identifiable, CaseIterable {
    case languages
    case dates
    case measurements
    case names
    case numbers
    
    var id: AppScreen { self }
}

extension AppScreen {
    var label: some View {
        switch self {
        case .languages:
            Label(LocalizedStringKey("भाषाएँ") /* Languages */, systemImage: "globe")
        case .dates:
            Label(LocalizedStringKey("तारीख़ व समय") /* Dates & Times */, systemImage: "clock")
        case .measurements:
            Label(LocalizedStringKey("माप") /* Measurements */, systemImage: "speedometer")
        case .names:
            Label(LocalizedStringKey("नाम") /* Names */, systemImage: "person")
        case .numbers:
            Label(LocalizedStringKey("संख्या") /* Numbers */, systemImage: "textformat.123")
        }
    }
    
    @MainActor
    @ViewBuilder var destination: some View {
        switch self {
        case .languages:
           LanguagesView()
        case .dates:
            DatesView()
        case .measurements:
            MeasurementsView()
        case .names:
            NamesView()
        case .numbers:
            NumbersView()
        }
    }
}
