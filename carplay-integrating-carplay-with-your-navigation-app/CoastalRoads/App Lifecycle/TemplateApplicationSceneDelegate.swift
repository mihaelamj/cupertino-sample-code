/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`TemplateApplicationSceneDelegate` is the delegate for the `CPTemplateApplicationScene` on the CarPlay display.
*/

import CarPlay
import UIKit

class TemplateApplicationSceneDelegate: NSObject {
    
    // MARK: UISceneDelegate
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if scene is CPTemplateApplicationScene, session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene will connect.")
        } else if scene is CPTemplateApplicationDashboardScene, session.configuration.name == "DashboardSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application dashboard scene will connect.")
        } else if scene is CPTemplateApplicationInstrumentClusterScene, session.configuration.name == "InstrumentClusterSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application instrument cluster scene will connect.")
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene did disconnect.")
        } else if scene.session.configuration.name == "DashboardSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application dashboard scene did disconnect.")
        } else if scene.session.configuration.name == "InstrumentClusterSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application instrument cluster scene did disconnect.")
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene did become active.")
            TemplateManager.shared.setActiveMapViewController(with: scene)
        } else if scene.session.configuration.name == "DashboardSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application dashboard scene did become active.")
            TemplateManager.shared.setActiveMapViewController(with: scene)
        } else if scene.session.configuration.name == "InstrumentClusterSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application instrument cluster scene did become active.")
            TemplateManager.shared.setActiveMapViewController(with: scene)
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene will resign active.")
        } else if scene.session.configuration.name == "DashboardSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application dashboard scene will resign active.")
        } else if scene.session.configuration.name == "InstrumentClusterSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application instrument cluster scene will resign active.")
        }
    }
    
}

// MARK: CPTemplateApplicationSceneDelegate

extension TemplateApplicationSceneDelegate: CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay.")
        TemplateManager.shared.interfaceController(interfaceController, didConnectWith: window, style: templateApplicationScene.contentStyle)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        TemplateManager.shared.interfaceController(interfaceController, didDisconnectWith: window)
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay.")
    }
}

extension TemplateApplicationSceneDelegate: CPTemplateApplicationDashboardSceneDelegate {
    
    func templateApplicationDashboardScene(
        _ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene,
        didConnect dashboardController: CPDashboardController,
        to window: UIWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay dashboard.")
        TemplateManager.shared.dashboardController(dashboardController, didConnectWith: window)
    }
    
    func templateApplicationDashboardScene(
        _ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene,
        didDisconnect dashboardController: CPDashboardController,
        from window: UIWindow) {
        TemplateManager.shared.dashboardController(dashboardController, didDisconnectWith: window)
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay dashboard.")
    }
}

extension TemplateApplicationSceneDelegate: CPTemplateApplicationInstrumentClusterSceneDelegate {
    
    func templateApplicationInstrumentClusterScene(
        _ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene,
        didConnect instrumentClusterController: CPInstrumentClusterController) {
        MemoryLogger.shared.appendEvent("Connected to instrument cluster.")
            TemplateManager.shared.clusterController(instrumentClusterController,
                                                     didConnectWith: templateApplicationInstrumentClusterScene.contentStyle)
        }
    
    func templateApplicationInstrumentClusterScene(
        _ templateApplicationInstrumentClusterScene: CPTemplateApplicationInstrumentClusterScene,
        didDisconnectInstrumentClusterController instrumentClusterController: CPInstrumentClusterController) {
            TemplateManager.shared.clusterController(instrumentClusterController)
        MemoryLogger.shared.appendEvent("Disconnected from instrument cluster.")
    }
}
