/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The `AppShortcutProvider` for Soup Chef.
*/

import AppIntents

/// - Tag: AppShortcuts
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct SoupChefAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OrderSoup(),
            phrases: [
                "Order \(.applicationName)",
                "Order \(\.$soup) from \(.applicationName)"
            ],
            shortTitle: "Order Soup"
        )
    }
    static var shortcutTileColor: ShortcutTileColor = .orange
}
