/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The delegate that responds to `TemplateApplicationSceneDelegate` methods for the app's scene on the CarPlay display.
*/

import CarPlay
import UIKit

class CarPlayTemplateApplicationSceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        OrderingService.service.inCarPlay = true
        MemoryLogger.shared.appendEvent("Template application scene did connect.")
        TemplateManager.mananger.interfaceControllerDidConnect(interfaceController, scene: templateApplicationScene)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        OrderingService.service.inCarPlay = false
        MemoryLogger.shared.appendEvent("Template application scene did disconnect.")
        TemplateManager.mananger.interfaceControllerDidDisconnect(interfaceController, scene: templateApplicationScene)
    }
}
