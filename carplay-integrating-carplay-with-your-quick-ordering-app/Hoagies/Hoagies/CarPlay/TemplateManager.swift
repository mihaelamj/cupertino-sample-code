/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Methods for managing the `CPTemplates` that the app displays.
*/

import CarPlay
import Foundation
import os

class TemplateManager: NSObject {
    
    static let mananger = TemplateManager()
    
    // A custom class that provides test data for use in the app.
    private class CustomLocalSearchResponse: MKLocalSearch.Response {
        
        override var mapItems: [MKMapItem] {
            return TestHoagieData.testMapItems().compactMap { item in
                item.mapItem
            }
        }
        
        override var boundingRegion: MKCoordinateRegion {
            return TestHoagieData.testRegion
        }
    }

    // A custom class that returns a custom response with the app's locations.
    private class CustomLocalSearch: MKLocalSearch {
        override func start(completionHandler: @escaping MKLocalSearch.CompletionHandler) {
            completionHandler(CustomLocalSearchResponse(), nil)
        }
    }

    var carplayInterfaceController: CPInterfaceController?
    
    var boundingRegion: MKCoordinateRegion = MKCoordinateRegion(.world)
    private let locationManager = CLLocationManager()
    
    private var carplayScene: CPTemplateApplicationScene?
    private var sessionConfiguration: CPSessionConfiguration?
    
    private var localSearch: CustomLocalSearch? {
        willSet {
            // Clear the results and cancel the currently running local search before starting a new search.
            localSearch?.cancel()
        }
    }

    // MARK: CPTemplateApplicationSceneDelegate
    
    /// - Tag: did_connect
    func interfaceControllerDidConnect(_ interfaceController: CPInterfaceController, scene: CPTemplateApplicationScene) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay window.")
        carplayInterfaceController = interfaceController
        carplayScene = scene
        carplayInterfaceController?.delegate = self
        sessionConfiguration = CPSessionConfiguration(delegate: self)
        locationManager.delegate = self
        requestLocation()
        setupMap()
    }
    
    func setupMap() {
        let pointOfInterestTemplate = CPPointOfInterestTemplate(
            title: "Hoagie Options",
            pointsOfInterest: [],
            selectedIndex: NSNotFound)
        pointOfInterestTemplate.pointOfInterestDelegate = self
        pointOfInterestTemplate.tabTitle = "Map"
        pointOfInterestTemplate.tabImage = UIImage(systemName: "car")!
        
        let tabTemplate = CPTabBarTemplate(templates: [pointOfInterestTemplate])
        
        carplayInterfaceController?.setRootTemplate(tabTemplate, animated: true, completion: { (done, error) in
            // Note: Ensure that 12 is the maximum POI locations that appear on the display.
            self.search(for: "Hoagies")
        })
    }
    
    func interfaceControllerDidDisconnect(_ interfaceController: CPInterfaceController, scene: CPTemplateApplicationScene) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay window.")
        carplayInterfaceController = nil
    }
    
    func updatePointsOfInterestWithMapItems(_ items: [MKMapItem]) {
        let places = items.map({ (item) -> CPPointOfInterest in
            return CPPointOfInterest(
                location: item,
                title: item.name ?? "",
                subtitle: item.phoneNumber,
                summary: item.placemark.formattedAddressWithNewLines,
                detailTitle: item.name,
                detailSubtitle: item.phoneNumber,
                detailSummary: item.placemark.formattedAddressWithNewLines,
                pinImage: UIImage(systemName: "car")!)
        })

        for place in places {
            setButtons(place: place)
        }
        
        guard
            let rootTemplate = carplayInterfaceController?.rootTemplate as? CPTabBarTemplate,
            let pointOfInterestTemplate = rootTemplate.templates.first as? CPPointOfInterestTemplate else {
            fatalError("CPPointOfInterestTemplate should be present as the 1st tab")
        }
        
        pointOfInterestTemplate.setPointsOfInterest(places, selectedIndex: NSNotFound)
        rootTemplate.updateTemplates([pointOfInterestTemplate, listTemplateFromPlaces(places)])
        
    }
    
    func dismissAlertAndPopToRootTemplate(completion: (() -> Void)? = nil) {
        carplayInterfaceController?.dismissTemplate(animated: true, completion: { [weak self] (done, error) in
            if self?.handleError(error, prependedMessage: "Error dismissing alert") == false {
                self?.carplayInterfaceController?.popToRootTemplate(animated: true) { (done, error) in
                    self?.handleError(error, prependedMessage: "Error popping to root template")
                    if let completion = completion {
                        completion()
                    }
                }
            }
        })
    }
    
    @discardableResult
    func handleError(_ error: Error?, prependedMessage: String) -> Bool {
        if let error = error {
            MemoryLogger.shared.appendEvent("\(prependedMessage): \(error.localizedDescription).")
        }
        return error != nil
    }
    
    private func listTemplateFromPlaces(_ places: [CPPointOfInterest]) -> CPListTemplate {
        let storeListTemplate = CPListTemplate(
            title: "Locations",
            sections: [CPListSection(items: places.compactMap({ (place) -> CPListItem in
                let listItem = CPListItem(text: place.title, detailText: place.summary)
                listItem.handler = { [weak self] item, completion in
                    self?.showOrderTemplate(place: place)
                    completion()
                }
                return listItem
            }))])
        
        storeListTemplate.tabTitle = "List"
        storeListTemplate.tabImage = UIImage(systemName: "list.star")!
        return storeListTemplate
    }
    
    private func setButtons(place: CPPointOfInterest) {
        /// - Tag: map
        // Make ordering the primary button.
        let button = CPTextButton(title: "Order", textStyle: .normal, handler: { (button) in
            MemoryLogger.shared.appendEvent("Order tapped \(place).")
            self.showOrderTemplate(place: place)
        })
        place.primaryButton = button
        // Try directions or a phone number as the secondary button.
        if let address = place.summary,
           let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics),
           let lon = place.location.placemark.location?.coordinate.longitude,
           let lat = place.location.placemark.location?.coordinate.latitude,
           let url = URL(string: "maps://?q=\(encodedAddress)&ll=\(lon),\(lat)") {
            place.secondaryButton = CPTextButton(title: "Directions", textStyle: .normal, handler: { (button) in
                MemoryLogger.shared.appendEvent("Opening Maps with \(address).")
                self.carplayScene?.open(url, options: nil, completionHandler: nil)
            })
        } else if let phoneNumber = place.subtitle, let url = URL(string: "tel://" + phoneNumber.replacingOccurrences(of: " ", with: "")) {
            place.secondaryButton = CPTextButton(title: "Call", textStyle: .normal, handler: { (button) in
                MemoryLogger.shared.appendEvent("Calling \(phoneNumber).")
                self.carplayScene?.open(url, options: nil, completionHandler: nil)
            })
        }
    }
    
    private func showOrderTemplate(place: CPPointOfInterest) {
        let alert = alertForPlace(place)
        let infoTemplate = CPInformationTemplate(
            title: "Order Options",
            layout: CPInformationTemplateLayout.twoColumn,
            items: [TestHoagieData.lastOrder(), TestHoagieData.houseFavoriteOrder()].compactMap({ (orderItem) -> CPInformationItem in
                return CPInformationItem(title: orderItem.type, detail: orderItem.order.joined(separator: ""))
            }),
            actions: [
                CPTextButton(title: "Last Order", textStyle: .confirm, handler: { [weak self] (button) in
                    MemoryLogger.shared.appendEvent("Ordering last \(place).")
                    do {
                        try OrderingService.placeOrder(hoagieOrder: TestHoagieData.lastOrder())
                        self?.carplayInterfaceController?.presentTemplate(alert, animated: true) { (done, error) in
                            self?.handleError(error, prependedMessage: "Error presenting \(alert.classForCoder)")
                        }
                    } catch {
                        self?.handleError(error, prependedMessage: "Error presenting \(alert.classForCoder)")
                    }
                }),
                CPTextButton(title: "House Favorite", textStyle: .confirm, handler: { [weak self] (button) in
                    MemoryLogger.shared.appendEvent("Ordering favorite \(place).")
                    do {
                        try OrderingService.placeOrder(hoagieOrder: TestHoagieData
                            .houseFavoriteOrder())
                        self?.carplayInterfaceController?.presentTemplate(alert, animated: true) { (done, error) in
                            self?.handleError(error, prependedMessage: "Error presenting \(alert.classForCoder)")
                        }
                    } catch {
                        self?.handleError(error, prependedMessage: "Error presenting \(alert.classForCoder)")
                    }
                })
            ])
        
        // Two templates is the maximum for CarPlay quick-ordering apps. It's a good practice to validate in your apps.
        if let controller = carplayInterfaceController,
           controller.templates.count < 2 {
            carplayInterfaceController?.pushTemplate(infoTemplate, animated: true) { [weak self] (done, error) in
                self?.handleError(error, prependedMessage: "Error pushing \(infoTemplate.classForCoder)")
            }
        } else {
            carplayInterfaceController?.popToRootTemplate(animated: true) { [weak self] (done, error) in
                if self?.handleError(error, prependedMessage: "Error popping to root template") == false {
                    self?.carplayInterfaceController?.pushTemplate(infoTemplate, animated: true) { (done, error) in
                        self?.handleError(error, prependedMessage: "Error pushing \(infoTemplate.classForCoder)")
                    }
                }
            }
        }
    }
    
    private func alertForPlace(_ place: CPPointOfInterest) -> CPAlertTemplate {
        return CPAlertTemplate(
            titleVariants: ["Your order has been placed"],
            actions: [
                CPAlertAction(
                    title: "Done",
                    style: .default,
                    handler: { [weak self] (action) in
                        MemoryLogger.shared.appendEvent("Done tapped \(place).")
                        self?.dismissAlertAndPopToRootTemplate()
                    }
                ),
                CPAlertAction(
                    title: "Directions",
                    style: .default,
                    handler: { [weak self] (action) in
                        MemoryLogger.shared.appendEvent("Directions tapped \(place).")
                        if let address = place.summary,
                           let encodedAddress = address.addingPercentEncoding(
                            withAllowedCharacters: CharacterSet.alphanumerics),
                            let lon = place.location.placemark.location?.coordinate.longitude,
                            let lat = place.location.placemark.location?.coordinate.latitude,
                            let url = URL(string: "maps://?q=\(encodedAddress)&ll=\(lon),\(lat)") {
                            MemoryLogger.shared.appendEvent("Opening Maps with \(address).")
                            self?.dismissAlertAndPopToRootTemplate {
                                self?.carplayScene?.open(url, options: nil, completionHandler: nil)
                            }
                        }
                    }
                )
            ]
        )
    }
    
    private func requestLocation() {
        (locationManager.authorizationStatus == .authorizedWhenInUse ||
            locationManager.authorizationStatus == .authorizedAlways) ?
        locationManager.startUpdatingLocation() :
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func search(for queryString: String?) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = queryString
        
        // Confine the map search to an area around the person's current location.
        searchRequest.region = boundingRegion
        searchRequest.resultTypes = .pointOfInterest
        
        localSearch = CustomLocalSearch(request: searchRequest)
        localSearch?.start { [weak self] (response, error) in
            guard error == nil else {
                MemoryLogger.shared.appendEvent("An error occurred with search \(error!.localizedDescription).")
                return
            }
            guard let items = response?.mapItems else {
                MemoryLogger.shared.appendEvent("No items.")
                return
            }
            self?.updatePointsOfInterestWithMapItems(items)
            
            if let updatedRegion = response?.boundingRegion {
                self?.boundingRegion = updatedRegion
            }
        }
    }
}

extension TemplateManager: CPTabBarTemplateDelegate {
    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
        MemoryLogger.shared.appendEvent("Selected Tab: \(selectedTemplate).")
    }
}

/// - Tag: focus
extension TemplateManager: CPPointOfInterestTemplateDelegate {
    func pointOfInterestTemplate(_ aTemplate: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion) {
        MemoryLogger.shared.appendEvent("Region Changed: \(region).")
        // In your app, you need to update your search results when this triggers.
        boundingRegion = region
        search(for: "hoagies")
    }
}

extension TemplateManager: CPSessionConfigurationDelegate {
    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration,
                              limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
        MemoryLogger.shared.appendEvent("Limited UI changed: \(limitedUserInterfaces)")
    }
}

extension TemplateManager: CPInterfaceControllerDelegate {
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
}
