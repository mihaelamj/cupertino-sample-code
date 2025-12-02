/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A controller that runs a simple game game and collects simulated heart rate and heart beat data as the user plays.
*/

import UIKit
import Foundation
import HealthKit

class GameViewController: UIViewController, HealthStoreContainer, GameControllerHeartSensorSessionDelegate {

    @IBOutlet var startGameButton: UIButton!
    @IBOutlet var goodButton: UIButton!
    @IBOutlet var badButton: UIButton!
    
    @IBOutlet var pointsLabel: UILabel!
    
    private var gameButtons = [UIButton]()
    private var gamePoints = 0
    private var gameStartDate = Date()
    
    // The `HKHealthStore` that this view controller uses to query data.
    // This is set by the app delegate.
    var healthStore: HKHealthStore!
    private var gameControllerHeartSensorSession: GameControllerHeartSensorSession?
    private var quantitySeriesBuilder: HKQuantitySeriesSampleBuilder?
    private var heartbeatSeriesBuilder: HKHeartbeatSeriesBuilder?
    
    enum GameState {
        case gameOver
        case playing
    }
    
    private var state = GameState.gameOver
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameButtons = [goodButton, badButton]
        pointsLabel.isHidden = true
        gamePoints = 0
        
        setupFreshGameState()

    }
    
    private func startNewGame() {
        setupNewGameState()
        
        // Create the game heart sensor, and start it
        gameControllerHeartSensorSession = GameControllerHeartSensorSession(delegate: self)
        gameControllerHeartSensorSession?.start()
        
        playGameRound()
    }
    
    private func setupNewGameState() {
        startGameButton.isHidden = true
        gamePoints = 0
        updatePointsLabel(gamePoints)
        pointsLabel.textColor = .red
        pointsLabel.isHidden = false
    }
    
    private func playGameRound() {
        updatePointsLabel(gamePoints)
        displayRandomButton()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            if self.state == GameState.playing {
                if self.currentButton == self.goodButton {
                    self.gameOver()
                } else {
                    self.playGameRound()
                }
            }
        }
    }

    @IBAction func startGameButtonPressed(_ sender: Any) {
        state = GameState.playing
        startNewGame()
    }
    
    @IBAction func goodButtonPressed(_ sender: Any) {
        gamePoints += 1
        updatePointsLabel(gamePoints)
        goodButton.isHidden = true
        timer?.invalidate()
        playGameRound()
    }
    
    @IBAction func badButtonPressed(_ sender: Any) {
        badButton.isHidden = true
        timer?.invalidate()
        gameOver()
    }
    
    private var timer: Timer?
    private var currentButton: UIButton!
    
    private func displayRandomButton() {
        for mybutton in gameButtons {
            mybutton.isHidden = true
        }
        let buttonIndex = Int.random(in: 0..<gameButtons.count)
        currentButton = gameButtons[buttonIndex]
        currentButton.center = CGPoint(x: randomXCoordinate(), y: randomYCoordinate())
        currentButton.isHidden = false
    }
    
    private func gameOver() {
        state = GameState.gameOver
        pointsLabel.textColor = .brown
        gameControllerHeartSensorSession?.finish()
        saveGame(for: gameControllerHeartSensorSession)
        setupFreshGameState()
    }
    
    private func setupFreshGameState() {
        startGameButton.isHidden = false
        for mybutton in gameButtons {
            mybutton.isHidden = true
        }
        pointsLabel.alpha = 0.15
        currentButton = goodButton
        state = GameState.gameOver
    }
    
    private func randCGFloat(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
        return CGFloat.random(in: min..<max)
    }
    
    private func randomXCoordinate() -> CGFloat {
        let left = view.safeAreaInsets.left + currentButton.bounds.width
        let right = view.bounds.width - view.safeAreaInsets.right - currentButton.bounds.width
        return randCGFloat(left, right)
    }
    
    private func randomYCoordinate() -> CGFloat {
        let top = view.safeAreaInsets.top + currentButton.bounds.height
        let bottom = view.bounds.height - view.safeAreaInsets.bottom - currentButton.bounds.height
        return randCGFloat(top, bottom)
    }
    
    private func updatePointsLabel(_ newValue: Int) {
        pointsLabel.text = "\(newValue)"
    }
    
    private  func saveGame(for heartSensor: GameControllerHeartSensorSession?) {
        guard let identifier = heartSensor?.UUID.uuidString, let startDate = heartSensor?.startDate else {
            return
        }
        
        // You can use standard UserDefaults to save some basic information about the game.
        // The game identifier UUID can be used to later retrieve detail data for the game from HealthKit.
        let userDefaults = UserDefaults.standard
        let defaultKey = "games"
        var games = userDefaults.array(forKey: defaultKey) ?? [Any]()
        let game: [String: Any] = ["identifier": identifier, "score": gamePoints, "startDate": startDate]
        games.insert(game, at: 0)
        userDefaults.set(games, forKey: defaultKey)
    }
    
    // MARK: - GameControllerHeartSensorSessionDelegate
    
    func sessionDidStart(_ session: GameControllerHeartSensorSession, startDate: Date) {
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        // Create the quantitySeriesBuilder with healthStore, heartRateType, startDate, and device.
        self.quantitySeriesBuilder = HKQuantitySeriesSampleBuilder(healthStore: self.healthStore,
                                                                   quantityType: heartRateType,
                                                                   startDate: startDate,
                                                                   device: session.device)
        
        self.heartbeatSeriesBuilder = HKHeartbeatSeriesBuilder(healthStore: self.healthStore,
                                                               device: session.device,
                                                               start: startDate)
        
    }
    
    func sessionDidReceiveHeartRate(_ session: GameControllerHeartSensorSession, heartRate: HKQuantity, dateInterval: DateInterval) {
        
        do {
            try self.quantitySeriesBuilder?.insert(heartRate, for: dateInterval)
        } catch {
            fatalError("Could not insert quantity: \(error)")
        }
        
    }
    
    func sessionDidReceiveHeartBeat(_ session: GameControllerHeartSensorSession, timeIntervalSinceStart: TimeInterval, precededByGap: Bool) {
        
        self.heartbeatSeriesBuilder?.addHeartbeatWithTimeInterval(sinceSeriesStartDate: timeIntervalSinceStart, precededByGap: false) {
            (success, error) in

            guard success else {
                fatalError("Could not add heartbeat: \(String(describing: error))")
            }
        }
    }
    
    func sessionDidEnd(_ session: GameControllerHeartSensorSession, endDate: Date) {
        
        // Construct metadata for the series.
        let metadata: [String: Any] = [HKMetadataKeyHeartRateSensorLocation: HKHeartRateSensorLocation.hand.rawValue,
                                       HKMetadataKeyHeartRateMotionContext: HKHeartRateMotionContext.sedentary.rawValue,
                                       HKMetadataKeyExternalUUID: session.UUID.uuidString]
        
        // Finish the quantitySeriesBuilder with the metatdata and endDate.
        self.quantitySeriesBuilder?.finishSeries(metadata: metadata, endDate: endDate) {
            (samples, error) in
            
            guard samples != nil else {
                fatalError("Could not finish heart rate series: \(String(describing: error))")
            }
        }
        
        self.heartbeatSeriesBuilder?.addMetadata(metadata) {
            (success, error) in

            guard error == nil else {
                fatalError("Could not add metadata: \(String(describing: error))")
            }
        }
        self.heartbeatSeriesBuilder?.finishSeries {
            (heartbeatSeriesSample, error) in

            guard heartbeatSeriesSample != nil else {
                fatalError("Could not finish heart beat series sample: \(String(describing: error))")
            }
        }
    }
}
