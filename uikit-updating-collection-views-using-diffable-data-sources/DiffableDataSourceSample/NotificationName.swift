/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that declares app-specific notification names.
*/

import Foundation

extension NSNotification.Name {
    /// - Tag: NSNotificationName
    static let recipeDidAdd = Notification.Name("com.example.apple-samplecode.DiffableDataSourceSample.recipeDidAdd")
    static let recipeDidChange = Notification.Name("com.example.apple-samplecode.DiffableDataSourceSample.recipeDidChange")
    static let recipeDidDelete = Notification.Name("com.example.apple-samplecode.DiffableDataSourceSample.recipeDidDelete")

    static let selectedRecipesDidChange = Notification.Name("com.example.apple-samplecode.DiffableDataSourceSample.selectedRecipesDidChange")

    static let recipeCollectionsDidChange = Notification.Name("com.example.apple-samplecode.DiffableDataSourceSample.recipeCollectionsDidChange")
}

// Custom keys to use with userInfo dictionaries.
enum NotificationKeys: String {
    case recipe
    case recipeId
    case recipeCollections
    case selectedRecipeIds
}
