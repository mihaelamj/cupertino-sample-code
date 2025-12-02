/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to Notification.Name to define some notifications for ColorItem events.
*/

import Foundation

extension NSNotification.Name {

    static let colorItemUpdated = NSNotification.Name("com.example.apple-samplecode.PeekPopNavigation.ColorItemUpdated")
    static let colorItemDeleted = NSNotification.Name("com.example.apple-samplecode.PeekPopNavigation.ColorItemDeleted")

}
