/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable controller that handles an electric vehicle's charging influenced by EnergyKit.
*/

import EnergyKit
import OSLog

/// An observable controller that handles an electric vehicle's charging influenced by EnergyKit.
@Observable class ElectricVehicleController {
    // MARK: Charging Parameters
    /// A charging window to indicate when a person plugs and unplugs their EV from power.
    var chargingWindow: DateInterval = .init(start: Date(), end: Date().addingTimeInterval(60 * 60 * 10))
    /// An incremental portion of the simulation, in seconds.
    var timestep: TimeInterval = 60

    // MARK: Electric Vehicle (EV)
    /// The configuration of the EV.
    var configuration: ElectricVehicle
    /// The EV snapshots for UI purposes.
    var snapshots: [ElectricVehicle] = []

    // MARK: EnergyKit
    /// The EV load event session.
    var session: ElectricVehicleLoadEvent.Session?

    // Electricity Guidance
    /// The guidance stored at the EV.
    var currentGuidance: ElectricityGuidance {
        didSet {
            chargingSchedule = calculateEVChargingSchedule()
        }
    }
    /// A Boolean that indicates whether the EV follows guidance.
    var isFollowingGuidance: Bool = true

    /// The venue at which the EV uses energy.
    var currentVenue: EnergyVenue

    /// The list of generated EV load events.
    var events = [ElectricVehicleLoadEvent]()

    /// The generated EV insights.
    var insights = [ElectricityInsightRecord<Measurement<UnitEnergy>>]()

    /// The EV charging schedule.
    var chargingSchedule: [DateInterval] = []

    init (
        /// An energy venue for the controller.
        venue: EnergyVenue,
        /// A guidance object for the controller.
        guidance: ElectricityGuidance
    ) {
        // Device identifier
        let deviceIdentifier = "C621E1F8-A36B-495A-93FC-0C247A3E6F5E"

        // Assume the EV charges from zero.
        self.configuration = .init(
            state: .init(
                timestamp: Date(),
                stateOfCharge: 43.0,
                powerLevel: 0.0,
                cumulativeEnergy: 0.0,
                isCharging: false
            ),
            properties: .init(
                desiredStateOfCharge: 98,
                chargingPower: 7.0,
                batteryCapacity: 60.0,
                vehicleID: deviceIdentifier
            )
        )
        self.currentVenue = venue
        self.currentGuidance = guidance
        self.chargingSchedule = calculateEVChargingSchedule()
    }
    
    // MARK: Setters
    func setElectricityGuidance(newValue: ElectricityGuidance) {
        currentGuidance = newValue
    }

    func setEnergyVenue(newValue: EnergyVenue) {
        currentVenue = newValue
    }
    
    // MARK: Managed EV Charging Helper Functions
    fileprivate func energyRequiredToFullCharge() -> Double {
        if configuration.properties.desiredStateOfCharge <= configuration.state.stateOfCharge {
            return 0
        }
        return configuration.properties.batteryCapacity * (configuration.properties.desiredStateOfCharge - configuration.state.stateOfCharge) / 100
    }
    
    fileprivate func calculateEVChargingSchedule() -> [DateInterval] {
        return selectingChargingIntervals()
    }
    
    fileprivate func selectingChargingIntervals() -> [DateInterval] {
        // The state of the car and guidance for the given period.
        let energyRequired = energyRequiredToFullCharge()
        let timeAvailableForCharging = chargingWindow.duration
        let timeRequiredForCharging = 60 * 60 * (energyRequired / configuration.properties.chargingPower)
        if timeRequiredForCharging >= timeAvailableForCharging {
            // Always charge; there's no time for tradeoffs.
            isFollowingGuidance = false
            return [chargingWindow]
        } else {
            // Tradeoffs are possible; sort guidance by energy quality and allocate it.
            return selectCleanestChargingIntervals(
                chargeTimeRequired: timeRequiredForCharging,
                guidance: currentGuidance,
                chargeWindow: chargingWindow
            )
        }
        
    }
    
    fileprivate func selectCleanestChargingIntervals(
        chargeTimeRequired: Double,
        guidance: ElectricityGuidance,
        chargeWindow: DateInterval
    ) -> [DateInterval] {
        let sortedGuidance = guidance.values.sorted { $0.rating < $1.rating }
        var chosenIntervals: [DateInterval] = []
        var totalTimeSelected = 0.0
        for guidance in sortedGuidance {
            if guidanceIntervalIsInChargingWindow(
                guidanceInterval: guidance.interval,
                chargingWindow: chargeWindow) {
                // Select the charging window for full or partial charging.
                if totalTimeSelected < chargeTimeRequired {
                    chosenIntervals.append(guidance.interval)
                    totalTimeSelected += guidance.interval.duration
                }
            }
        }
        return chosenIntervals.sorted { $0.start < $1.start }
    }
    
    fileprivate func guidanceIntervalIsInChargingWindow(
        guidanceInterval: DateInterval,
        chargingWindow: DateInterval
    ) -> Bool {
        // It's fine if the charging window ends before the guidance window ends.
        return guidanceInterval.start >= chargingWindow.start
    }
    
    fileprivate func simulateCharging() {
        if configuration.state.stateOfCharge < configuration.properties.desiredStateOfCharge {
            // If the timestamp lies in a charging window, update the EV state to charging.
            if chargingSchedule.contains(where: { $0.contains(configuration.state.timestamp) }) {
                if configuration.setIsCharging(true) && configuration.state.cumulativeEnergy == 0 {
                    // Begin the session, as charging is about to start.
                    createLoadEvent(sessionState: .begin)
                } else {
                    // The EV is actively charging.
                    let minutes = Calendar.current.component(.minute, from: configuration.state.timestamp)
                    if minutes == 0 || minutes == 15 || minutes == 30 || minutes == 45 {
                        // Create load events on 15-minute boundaries.
                        createLoadEvent(sessionState: .active)
                    }
                }
            } else {
                if configuration.setIsCharging(false),
                   abs(configuration.state.stateOfCharge - configuration.properties.desiredStateOfCharge) <= 1.0 {
                    // End the session, as charging is complete.
                    createLoadEvent(sessionState: .end)
                }
            }
            updateEVState()
        } else {
            // The EV is fully charged; finish charging session and create a load event.
            _ = configuration.setIsCharging(false)
            if events.last?.session.state != .end {
                createLoadEvent(sessionState: .end)
            }
        }
    }
    
    fileprivate func updateEVState() {
        // If charging is in progress, compute energy added during the time-step.
        if configuration.state.isCharging {
            configuration.setPowerLevel(configuration.properties.chargingPower)
            let energyAdded = configuration.properties.chargingPower * timestep / 3600
            configuration.increaseChargeLevel(by: 100 * energyAdded / configuration.properties.batteryCapacity)
            configuration.state.cumulativeEnergy += energyAdded
        } else {
            configuration.setPowerLevel(0)
        }
    }
    
    /// Save state for the UI.
    fileprivate func saveEVState() {
        self.snapshots.append(self.configuration)
    }

    /// Advance the simulation one time-step.
    fileprivate func updateSimulationTime() {
        let advancedTime = configuration.state.timestamp.addingTimeInterval(timestep)
        configuration.setTimestamp(advancedTime)
    }

    /// Run simulation for one time-step.
    fileprivate func runSimulationStepWithGuidance() {
        simulateCharging()
        updateSimulationTime()
        // Save the new state.
        saveEVState()
    }
    
    fileprivate func shouldChargeDuring(interval: DateInterval) -> Bool {
        return chargingSchedule.contains(where: { $0.contains(interval.start) })
    }

    fileprivate func beginSession() {
        session = ElectricVehicleLoadEvent.Session(
            id: UUID(),
            state: .begin,
            guidanceState: .init(
                wasFollowingGuidance: isFollowingGuidance,
                guidanceToken: currentGuidance.guidanceToken
            )
        )
    }

    fileprivate func updateSession() {
        if let session {
            self.session = ElectricVehicleLoadEvent.Session(
                id: session.id,
                state: .active,
                guidanceState: .init(
                    wasFollowingGuidance: isFollowingGuidance,
                    guidanceToken: currentGuidance.guidanceToken
                )
            )
        }
    }

    fileprivate func endSession() {
        if let session {
            self.session = ElectricVehicleLoadEvent.Session(
                id: session.id,
                state: .end,
                guidanceState: .init(
                    wasFollowingGuidance: isFollowingGuidance,
                    guidanceToken: currentGuidance.guidanceToken
                )
            )
        }
    }

    fileprivate func chargingMeasurement() -> ElectricVehicleLoadEvent.ElectricalMeasurement {
        let stateOfCharge = Int(configuration.state.stateOfCharge.rounded(.down))
        let power = Measurement<UnitPower>(
            value: configuration.properties.chargingPower * 1_000_000,
            unit: .milliwatts
        )
        let energy = Measurement<UnitEnergy>(
            value: configuration.state.cumulativeEnergy * 1_000_000,
            unit: .EnergyKit.milliwattHours
        )
        return ElectricVehicleLoadEvent.ElectricalMeasurement(
            stateOfCharge: stateOfCharge,
            direction: .imported,
            power: power,
            energy: energy
        )
    }

    fileprivate func createLoadEvent(
        sessionState: ElectricVehicleLoadEvent.Session.State
    ) {
        switch sessionState {
        case .begin:
            beginSession()
        case .active:
            updateSession()
        case .end:
            endSession()
        @unknown default:
            fatalError()
        }
        if let session {
            // Shift the timestamps 24 hours back for insights generation only,
            //  since this controller proceses a 24 hour forecast.
            // Simulate insights generation for past events instead of future events.
            let event = ElectricVehicleLoadEvent(
                timestamp: configuration.state.timestamp.addingTimeInterval(-86_400),
                measurement: chargingMeasurement(),
                session: session,
                deviceID: configuration.properties.vehicleID
            )
            // Add the load event.
            events.append(event)
        }
    }

    /// Run the simulation for energy guidance.
    func runSimulationWithGuidance() {
        for value in currentGuidance.values {
            if value.interval.contains(configuration.state.timestamp) {
                while configuration.state.timestamp < value.interval.end {
                    runSimulationStepWithGuidance()
                }
            } else {
                while configuration.state.timestamp < value.interval.start {
                    runSimulationStepWithGuidance()
                }
            }
        }
        // The simulation ends.
    }

    func submitEvents() async throws {
        try await currentVenue.submitEvents(events)
    }
}
