/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI hosting controller of the watch app.
*/

import SwiftUI

class HostingController: WKHostingController<AnyView> {
    override var body: AnyView {
        let delegate: ExtensionDelegate! = WKExtension.shared().delegate as? ExtensionDelegate
        return AnyView(ContentView().environmentObject(delegate.templateConfiguration))
    }
}
