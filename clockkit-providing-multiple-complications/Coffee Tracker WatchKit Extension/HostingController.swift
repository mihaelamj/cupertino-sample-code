/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays SwiftUI views.
*/

import SwiftUI

// The HostingController displays a SwiftUI view.
class HostingController: WKHostingController<ContentView> {
    
    // MARK: - Body Method
    
    override var body: ContentView {
        // Create and display the content wrapper.
        return ContentView()
    }
}
