/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`TemplateManager` manages the CPTemplates that Coastal Roads displays.
*/

import CarPlay
import Foundation
import os

// MARK: CPMapTemplate UI

extension TemplateManager {

    final private func panButtonPressed(_ sender: Any) {
        baseMapTemplate?.showPanningInterface(animated: true)

        let doneButton = CPBarButton(title: "Done") { (_) in
            self.baseMapTemplate?.dismissPanningInterface(animated: true)
            self.installBarButtons()
        }

        self.baseMapTemplate?.leadingNavigationBarButtons = [ doneButton ]
        self.baseMapTemplate?.trailingNavigationBarButtons = []
    }

    final func installBarButtons() {
        let panButton = CPBarButton(image: UIImage(
                                        named: "Pan",
                                        in: .main, compatibleWith: mainMapViewController.traitCollection)!
        ) { (btn) in
            // Pass panButton as sender.
            self.panButtonPressed(btn)
        }
        let destsButton = CPBarButton(image: UIImage(
                                        named: "Favorites",
                                        in: Bundle.main, compatibleWith: mainMapViewController.traitCollection)!
        ) { (_) in
            self.showGridTemplate()
        }
        baseMapTemplate?.leadingNavigationBarButtons = [panButton]
        baseMapTemplate?.trailingNavigationBarButtons = [destsButton]
    }
}

// MARK: MapViewActionProviding

extension TemplateManager: MapViewActionProviding {

    final func setZoomInEnabled(_ enabled: Bool) {
        if let zoomInButton = baseMapTemplate?.mapButtons.first {
            zoomInButton.isEnabled = enabled
        }
    }

    final func setZoomOutEnabled(_ enabled: Bool) {
        if let zoomOutButton = baseMapTemplate?.mapButtons.last {
            zoomOutButton.isEnabled = enabled
        }
    }
}

// MARK: CPMapTemplateDelegate

/// - Tag: override
extension TemplateManager: CPMapTemplateDelegate {

    func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        mainMapViewController.panInDirection(direction)
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        mainMapViewController.setPolylineVisible(true)
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {

        MemoryLogger.shared.appendEvent("Beginning navigation guidance.")

        let navSession = mapTemplate.simulateCoastalRoadsNavigation(
            trip: trip,
            routeChoice: routeChoice,
            traitCollection: mainMapViewController.traitCollection)
        navigationSession = navSession

        simulateNavigation(for: navSession, maneuvers: mapTemplate.coastalRoadsManeuvers(compatibleWith: mainMapViewController.traitCollection))
    }

    // When this sample app enters the background, you will no longer see banner notifications.
    // This is because the simulation occurs in conjunction with the CADisplayLink, which pauses
    // when the app enters the background.
    func mapTemplate(_ mapTemplate: CPMapTemplate,
                     shouldUpdateNotificationFor maneuver: CPManeuver,
                     with travelEstimates: CPTravelEstimates) -> Bool {
        return true
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, shouldShowNotificationFor navigationAlert: CPNavigationAlert) -> Bool {
        return true
    }
}

// MARK: Navigation

extension TemplateManager {

    final func beginNavigation(fromDashboard: Bool = false) {
        
        let cancelButton = CPBarButton(title: "Cancel") { (_) in
            self.endNavigation(cancelled: true)
        }

        let route = CPRouteChoice(summaryVariants: ["via Solar Circle"],
                                  additionalInformationVariants: ["Possible meteor shower."],
                                  selectionSummaryVariants: [])

        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
        destinationItem.name = "Mars Meadow"
        let trip = CPTrip(origin: MKMapItem(), destination: destinationItem, routeChoices: [route])

        let estimates = CPTravelEstimates(distanceRemaining: NSMeasurement(doubleValue: 4500, unit: UnitLength.meters) as Measurement<UnitLength>,
                                          timeRemaining: 360)
        currentTravelEstimates = estimates

        baseMapTemplate?.showTripPreviews([trip], selectedTrip: nil,
                                          textConfiguration: CPTripPreviewTextConfiguration(startButtonTitle: "Launch",
                                                                                            additionalRoutesButtonTitle: "More Routes",
                                                                                            overviewButtonTitle: "Overview"))
        baseMapTemplate?.updateEstimates(estimates, for: trip)
        baseMapTemplate?.leadingNavigationBarButtons = [cancelButton]
        baseMapTemplate?.trailingNavigationBarButtons = []
        activeMapViewController?.setPolylineVisible(true)
        
        if fromDashboard == false {
            activeMapViewController?.mapView.zoomToLocation(.routeOverview)
        }
    }

    final private func endNavigation(cancelled: Bool) {
        MemoryLogger.shared.appendEvent("Navigation guidance ended.")

        displayLink?.invalidate()
        displayLink = nil

        if cancelled {
            navigationSession?.cancelTrip()
        } else {
            navigationSession?.finishTrip()
        }

        activeManeuver = nil
        activeEstimates = nil
        lastCompletedManeuverFrame = nil
        currentTravelEstimates = nil

        baseMapTemplate?.hideTripPreviews()
        installBarButtons()
        //only restore zoom to routeOverview on main Mapview
        activeMapViewController?.setPolylineVisible(false)
        mainMapViewController.mapView.zoomToLocation(.routeOverview)
        
        // enable zooming.
        setZoomInEnabled(true)
        setZoomOutEnabled(true)
    }

    @objc
    func displayLinkFired(_ sender: CADisplayLink) {
        guard let maneuver = self.activeManeuver else { return }
        guard let estimates = self.activeEstimates else { return }
        guard let maneuverEndValue = maneuver.userInfo as? NSValue else { return }
        guard let maneuverStartFrame = self.lastCompletedManeuverFrame else { return }
        let maneuverEndFrame = maneuverEndValue.cgRectValue

        let totalDistance = maneuver.initialTravelEstimates?.distanceRemaining.value ?? 0
        let completedDistance = totalDistance - estimates.distanceRemaining.value
        let progress = CGFloat(completedDistance / totalDistance)

        guard progress >= 0 && progress < 1 else { return }

        func interpolate(start: CGFloat, end: CGFloat, progress: CGFloat) -> CGFloat {
            return start + ((end - start) * progress)
        }

        let interpolatedRect = CGRect(x: interpolate(start: maneuverStartFrame.origin.x,
                                                     end: maneuverEndFrame.origin.x, progress: progress),
                                      y: interpolate(start: maneuverStartFrame.origin.y,
                                                     end: maneuverEndFrame.origin.y, progress: progress),
                                      width: interpolate(start: maneuverStartFrame.size.width,
                                                         end: maneuverEndFrame.size.width, progress: progress),
                                      height: interpolate(start: maneuverStartFrame.size.height,
                                                          end: maneuverEndFrame.size.height, progress: progress)
            ).integral
        //adjust here based on the different view size of windows
        activeMapViewController?.mapView.setContentOffset(interpolatedRect.origin, animated: false)
    }

    final private func evaluateManeuver(maneuver: CPManeuver, currentManeuverIndex: Int) {
        switch currentManeuverIndex {
        case 0: maneuver.userInfo = NSValue(cgRect: CRZoomLocation.routeOrigin.frame)
        case 1: maneuver.userInfo = NSValue(cgRect: CRZoomLocation.routeTurn1.frame)
        case 2: maneuver.userInfo = NSValue(cgRect: CRZoomLocation.routeTurn2.frame)
        case 3: maneuver.userInfo = NSValue(cgRect: CRZoomLocation.routeTurn3.frame)
        case 4: maneuver.userInfo = NSValue(cgRect: CRZoomLocation.routeDestination.frame)
        default: break
        }
    }

    final private func updateDistance(_ distance: Double, for maneuver: CPManeuver, session: CPNavigationSession) {
        DispatchQueue.main.sync {
            let newDistance = Measurement(value: distance, unit: UnitLength.meters)
            let estimates = CPTravelEstimates(distanceRemaining: newDistance as Measurement<UnitLength>, timeRemaining: 0)
            self.activeEstimates = estimates
            session.updateEstimates(estimates, for: maneuver)
        }
    }

    // In a real CarPlay app, actual navigation should occur. This method is purely for simulation purposes.
    final private func simulateNavigation(for session: CPNavigationSession, maneuvers: [CPManeuver]) {
        var currentManeuverIndex = 0
        var completedRoute = false

        // At the start of guidance, move the viewport to the first point of interest.
        activeMapViewController?.mapView.zoomToLocation(.routeTurn1)

        if let currentDisplayLink = activeMapViewController?.view.window?.screen.displayLink(
            withTarget: self,
            selector: #selector(displayLinkFired(_:))) {
            currentDisplayLink.add(to: .main, forMode: .common)
            displayLink = currentDisplayLink
        }

        // Since this is a simulation with an image instead of an actual route, disable zoom to prevent going off-screen.
        setZoomInEnabled(false)
        setZoomOutEnabled(false)

        DispatchQueue.global(qos: .background).async {
            repeat {
                DispatchQueue.main.sync {
                    if currentManeuverIndex < maneuvers.count {

                        if currentManeuverIndex > 0 {
                            self.lastCompletedManeuverFrame = (maneuvers[currentManeuverIndex - 1].userInfo as? NSValue)?.cgRectValue
                        }

                        let maneuver = maneuvers[currentManeuverIndex]
                        self.activeManeuver = maneuver
                        session.upcomingManeuvers = [maneuver]
                        currentManeuverIndex += 1
                        self.evaluateManeuver(maneuver: maneuver, currentManeuverIndex: currentManeuverIndex)
                    } else {
                        completedRoute = true
                        self.endNavigation(cancelled: false)
                    }
                }

                guard var distance = self.activeManeuver?.initialTravelEstimates?.distanceRemaining.value else { continue }
                // Update the distance panel and drive the simulation by decrementing the distance in a while loop.
                repeat {
                    guard let maneuver = self.activeManeuver else { return }
                    self.updateDistance(distance, for: maneuver, session: session)
                    distance -= 5
                    usleep(600)
                } while (distance >= 0)

                let remainingSteps = maneuvers.count - currentManeuverIndex - 1
                let multiplier = Double(remainingSteps) / Double(maneuvers.count)
                let distanceRemaining = max(0, (self.currentTravelEstimates?.distanceRemaining.value ?? 0) * multiplier)
                let timeRemaining = max(0, (self.currentTravelEstimates?.timeRemaining ?? 0) * multiplier)

                let tripDistance = Measurement(value: distanceRemaining, unit: UnitLength.meters)
                let newEstimates = CPTravelEstimates(distanceRemaining: tripDistance,
                                                     timeRemaining: timeRemaining)

                self.baseMapTemplate?.updateEstimates(newEstimates, for: session.trip)

            } while (!completedRoute)
        }
    }
}

// Custom card color
extension UIColor {
    static var cornflowerBlue: UIColor {
        return UIColor(displayP3Red: 100.0 / 255.0, green: 149.0 / 255.0, blue: 237.0 / 255.0, alpha: 1.0)
    }
}
