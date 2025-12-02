/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Represents the profiles, and holds the currently selected one.
*/

import Foundation
import TVServices
import UIKit

struct Profile {
    struct Section {
        let name: String
        let symbols: [String]
    }

    let identifier: String
    let name: String
    let color: UIColor
    let sections: [Section]
    fileprivate let order: Int
}

class ProfileData {
    private let userManager: TVUserManager
    private let profiles: [String: Profile]
    private var selectedProfileIdentifier: String? {
        didSet {
            guard oldValue != selectedProfileIdentifier else { return }

            // If running on tvOS 16, check if the selected profile should be
            // remembered before storing it.
            if #available(tvOS 16.0, *), userManager.shouldStorePreferencesForCurrentUser {
                UserDefaults.standard.set(selectedProfileIdentifier, forKey: "PreferredProfileIdentifierKey")
            }

            NotificationCenter.default.post(name: .selectedProfileDidChange, object: nil)
        }
    }

    lazy var allProfiles: [Profile] = profiles.values.sorted(by: { $0.order < $1.order })

    var selectedProfile: Profile? {
        guard let selectedProfileIdentifier = self.selectedProfileIdentifier else {
            return nil
        }

        return profiles[selectedProfileIdentifier]
    }

    init() {
        userManager = TVUserManager()

        let newReleases = Profile.Section(name: "New Releases", symbols: ["🎂", "🕵🏽‍♀️", "🕷", "🧝🏼‍♀️", "🏍", "🚄", "💃🏿", "⛩", "🚥", "🎠"])
        profiles = [
            "100": Profile(identifier: "100", name: "Red", color: UIColor(hue: 2.9 / 3.0, saturation: 0.9, brightness: 0.9, alpha: 1.0), sections: [
                Profile.Section(name: "Continue Watching", symbols: ["🦑", "💵", "💣", "💥", "☃️", "🌊", "🐕"]),
                Profile.Section(name: "More For You", symbols: ["🦖", "🦂", "🏴‍☠️", "🔱", "🚓"]),
                newReleases
            ], order: 1),
            "010": Profile(identifier: "010", name: "Green", color: UIColor(hue: 0.9 / 3.0, saturation: 0.9, brightness: 0.9, alpha: 1.0), sections: [
                Profile.Section(name: "Continue Watching", symbols: ["🦄", "🚢", "🏰", "🏴󠁧󠁢󠁷󠁬󠁳󠁿", "🙉"]),
                Profile.Section(name: "More For You", symbols: ["🧸", "🌪", "💐", "🎪"]),
                newReleases
            ], order: 2),
            "001": Profile(identifier: "001", name: "Blue", color: UIColor(hue: 1.9 / 3.0, saturation: 0.9, brightness: 0.9, alpha: 1.0), sections: [
                Profile.Section(name: "Continue Watching", symbols: ["🛸", "🏇🏼", "🦹🏼‍♂️", "🏐", "🧛🏻‍♂️", "🎶", "👻"]),
                Profile.Section(name: "More For You", symbols: ["🎸", "👽", "🛩", "🦍", "⚽️"]),
                newReleases
            ], order: 3)
        ]

        selectedProfileIdentifier = UserDefaults.standard.string(forKey: "PreferredProfileIdentifierKey")
    }

    func profile(withIdentifier identifier: String) -> Profile? {
        return profiles[identifier]
    }

    func select(_ profile: Profile) {
        guard profiles[profile.identifier] != nil else {
            // Invalid profile, so fall back to clearing any selection.
            deselectProfile()
            return
        }

        selectedProfileIdentifier = profile.identifier
    }

    func deselectProfile() {
        selectedProfileIdentifier = nil
    }
}

extension Notification.Name {
    static let selectedProfileDidChange = Notification.Name("ProfileDataSelectedProfileDidChange")
}
