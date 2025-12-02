/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`TemplateManager` manages the CPTemplates that Coastal Roads displays.
*/

import CarPlay
import Foundation
import os

class TemplateManager: NSObject, CPInterfaceControllerDelegate, CPInstrumentClusterControllerDelegate, CPSessionConfigurationDelegate {
    
    static let shared = TemplateManager()

    private var carplayInterfaceController: CPInterfaceController?
    private var carWindow: UIWindow?
    private var instrumentClusterWindow: UIWindow?

    public private(set) var baseMapTemplate: CPMapTemplate?

    var currentTravelEstimates: CPTravelEstimates?
    var navigationSession: CPNavigationSession?
    var displayLink: CADisplayLink?
    var activeManeuver: CPManeuver?
    var activeEstimates: CPTravelEstimates?
    var lastCompletedManeuverFrame: CGRect?
    var sessionConfiguration: CPSessionConfiguration!
    
    let mainMapViewController = MapViewController(nibName: nil, bundle: nil)
    let dashboardMapViewController = MapViewController(nibName: nil, bundle: nil)
    let instrumentClusterViewController = MapViewController(nibName: nil, bundle: nil)

    var activeMapViewController: MapViewController?
    var dashboardMapViewOffset: CGPoint?
    var currentZoomScale: CGFloat?

    override init() {
        super.init()
        sessionConfiguration = CPSessionConfiguration(delegate: self)
       
        mainMapViewController.mapViewActionProvider = self
    }

    // MARK: CPInterfaceControllerDelegate
    
    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) will appear.")
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) did appear.")
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) will disappear.")
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) did disappear.")
    }

    // MARK: CPSessionConfigurationDelegate

    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration,
                              limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
        MemoryLogger.shared.appendEvent("Limited UI changed: \(limitedUserInterfaces)")
    }

    // MARK: CPMapTemplateDelegate

    func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {
        MemoryLogger.shared.appendEvent("Showing map panning interface.")
    }

    func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        MemoryLogger.shared.appendEvent("Dismissed map panning interface.")
    }
    
    // MARK: Response to UISceneDelegate
    // Determine which map view controller's view is actively showing.
    func setActiveMapViewController(with activeScene: UIScene) {
        if activeScene is CPTemplateApplicationScene {
            activeMapViewController = mainMapViewController
        } else if activeScene is CPTemplateApplicationInstrumentClusterScene {
            instrumentClusterWindow?.rootViewController = instrumentClusterViewController
        } else if activeScene is CPTemplateApplicationDashboardScene {
            activeMapViewController = dashboardMapViewController
            // Set the same zoom scale as the mapView from mainMapViewController.
            if let mainMapView = mainMapViewController.mapView {
                // Calculate the mapView frame difference between mainMapViewController and dashboardMapViewController.
                dashboardMapViewController.setPolylineVisible(mainMapViewController.polylineVisible)
                if dashboardMapViewOffset == nil {
                    let offsetX = 0.5 * (mainMapView.frame.size.width - dashboardMapViewController.mapView.frame.width)
                    let offsetY = 0.5 * (mainMapView.frame.size.height - dashboardMapViewController.mapView.frame.height)
                    dashboardMapViewOffset = CGPoint(x: offsetX, y: offsetY)
                }
                let offset = CGPoint(
                    x: mainMapView.contentOffset.x + dashboardMapViewOffset!.x,
                    y: mainMapView.contentOffset.y + dashboardMapViewOffset!.y)
                activeMapViewController!.mapView.setContentOffset(offset, animated: true)
                activeMapViewController!.mapView.setZoomScale((mainMapView.zoomScale), animated: true)
            }
        }
    }
    
    // MARK: CPTemplateApplicationInstrumentClusterSceneDelegate
    
    func clusterController(_ clusterController: CPInstrumentClusterController, didConnectWith style: UIUserInterfaceStyle) {
        MemoryLogger.shared.appendEvent("Connected to instrument cluster controller.")
        clusterController.delegate = self
    }

    func clusterController(_ clusterController: CPInstrumentClusterController) {
        MemoryLogger.shared.appendEvent("Disconnected from instrument cluster controller.")
    }
    
    // MARK: CPInstrumentClusterControllerDelegate
    
    func instrumentClusterControllerDidConnect(_ instrumentClusterWindow: UIWindow) {
        MemoryLogger.shared.appendEvent("Connected to instrument cluster window.")
        self.instrumentClusterWindow = instrumentClusterWindow
    }
    
    func instrumentClusterControllerDidDisconnectWindow(_ instrumentClusterWindow: UIWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from instrument cluster window.")
    }
    
    func instrumentClusterControllerDidZoom(in instrumentClusterController: CPInstrumentClusterController) {
        self.instrumentClusterViewController.zoomIn()

    }
    
    func instrumentClusterControllerDidZoomOut(_ instrumentClusterController: CPInstrumentClusterController) {
        self.instrumentClusterViewController.zoomOut()
    }
    
    // MARK: CPTemplateApplicationDashboardSceneDelegate
    
    func dashboardController(_ dashboardController: CPDashboardController, didConnectWith window: UIWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay dashboard window.")
        
        //Or consider the button here is a short cut to my vaforite destination (home, work, shopping)
        let beachesButton = CPDashboardButton(
            titleVariants: ["Beaches"],
            subtitleVariants: ["Beach Trip"],
            image: #imageLiteral(resourceName: "gridBeaches")) { (button) in
                self.beginNavigation(fromDashboard: true)
        }
        
        let parksButton = CPDashboardButton(
            titleVariants: ["Parks"],
            subtitleVariants: ["Park Trip"],
            image: #imageLiteral(resourceName: "gridParks")) { (button) in
                self.beginNavigation(fromDashboard: true)
        }
        //here we should create different map view controller
        window.rootViewController = dashboardMapViewController
                                                           
        dashboardController.shortcutButtons = [beachesButton, parksButton]
    }

    func dashboardController(_ dashboardController: CPDashboardController, didDisconnectWith window: UIWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay dashboard window.")
    }
    
    /// - Tag: did_connect
    // MARK: CPTemplateApplicationSceneDelegate
    
    func interfaceController(_ interfaceController: CPInterfaceController, didConnectWith window: CPWindow, style: UIUserInterfaceStyle) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay window.")

        carplayInterfaceController = interfaceController
        carplayInterfaceController!.delegate = self
        
        window.rootViewController = mainMapViewController
        carWindow = window
        
        let mapTemplate = CPMapTemplate.coastalRoadsMapTemplate(compatibleWith: mainMapViewController.traitCollection, zoomInAction: {
            MemoryLogger.shared.appendEvent("Map zoom in.")
            self.mainMapViewController.zoomIn()
        }, zoomOutAction: {
            MemoryLogger.shared.appendEvent("Map zoom out.")
            self.mainMapViewController.zoomOut()
        })

        mapTemplate.mapDelegate = self

        baseMapTemplate = mapTemplate

        installBarButtons()

        interfaceController.setRootTemplate(mapTemplate, animated: true) { (success, _) in
            if success {
                MemoryLogger.shared.appendEvent("Root MapTemplate set successfully")
            }
        }
    }

    func interfaceController(_ interfaceController: CPInterfaceController, didDisconnectWith window: CPWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay window.")
        carplayInterfaceController = nil
        carWindow?.isHidden = true
    }

    // MARK: Template Generators

    func showGridTemplate() {
        let gridTemplate = CPGridTemplate.favoritesGridTemplate(compatibleWith: mainMapViewController.traitCollection) {
            // Set title if it exists, otherwise name it "Favorites".
            button in self.showListTemplate(title: button.titleVariants.first ?? "Favorites")
        }

        carplayInterfaceController?.pushTemplate(gridTemplate, animated: true) { (_, _) in }
    }

    func showListTemplate(title: String) {
        let listTemplate = CPListTemplate.searchResultsListTemplate(
            compatibleWith: mainMapViewController.traitCollection,
            title: title,
            interfaceController: carplayInterfaceController)
        carplayInterfaceController?.pushTemplate(listTemplate, animated: true) { (_, _) in }
    }
}
