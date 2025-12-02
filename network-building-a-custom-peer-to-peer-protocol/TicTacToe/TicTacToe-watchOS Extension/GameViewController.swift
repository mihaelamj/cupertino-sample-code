/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Build a view controller for Tic-Tac-Toe gameplay.
*/

import SpriteKit
import Network
import WatchKit
import Foundation

enum GameCharacterFamily: String, CaseIterable {
    case monkeys
    case bears
    case birds

    func emojiArray() -> [String] {
        switch self {
        case .monkeys: return ["🙈", "🙉", "🙊"]
        case .bears: return ["🐻", "🐼", "🐨"]
        case .birds: return ["🐧", "🐔", "🐤"]
        }
    }

    init?(_ emoji: String) {
        switch emoji {
        case "🙈", "🙉", "🙊": self = .monkeys
        case "🐼", "🐨", "🐻": self = .bears
        case "🐔", "🐤", "🐧": self = .birds
        default: return nil
        }
    }
}

enum GameResult {
    case inProgress
    case catsGame
    case playerWon(character: String)
}

class GameViewController: WKInterfaceController {

    @IBOutlet var skInterface: WKInterfaceSKScene!
    
    var selectedFamily: GameCharacterFamily?
    var peerSelectedFamily: GameCharacterFamily?

    func declareWinner(_ string: String) {
        if let sceneView = skInterface,
            let scene = sceneView.scene as? GameScene {
            scene.hideSelectSquares()
            scene.isUserInteractionEnabled = false
        }
        let alertAction = WKAlertAction(title: "Resign", style: .default) { () -> Void in
            self.stopGame()
        }
        presentAlert(withTitle: "Game Over", message: "\(string)", preferredStyle: .alert, actions: [alertAction])
    }

    func handleMyTurnSelectFamily() {
        // Disable the family the peer selects.
        repeat {
            selectedFamily = GameCharacterFamily.allCases.randomElement()
        } while (selectedFamily == peerSelectedFamily)
        
        guard let character = selectedFamily!.emojiArray().first else {
            return
        }
        
        // Select a family.
        sharedConnection?.selectCharacter(character)
        handleTurn(false)
    }

    func handleWaitingToSelectFamily() {
        print("Waiting for other player to select family")
    }

    func handleMyTurn() {
        if let sceneView = skInterface,
            let scene = sceneView.scene as? GameScene {
            scene.showSelectSquares()
        }
    }

    func handleWaitingForTurn() {
        if let sceneView = skInterface,
            let scene = sceneView.scene as? GameScene {
            scene.hideSelectSquares()
        }
    }

    func handleTurn(_ myTurn: Bool) {
        if let sceneView = skInterface,
            let scene = sceneView.scene as? GameScene {
            switch scene.gameResult() {
            case .catsGame:
                declareWinner("🐱's Game!")
                return
            case .playerWon(let winningCharacter):
                declareWinner("\(winningCharacter) Wins!")
                return
            case .inProgress:
                // Continue handling more turns.
                break
            }
        }
        if selectedFamily == nil {
            // First, let the user select a character family.
            if myTurn {
                handleMyTurnSelectFamily()
            } else {
                handleWaitingToSelectFamily()
            }
        } else {
            // Then, let the user make a move.
            if myTurn {
                handleMyTurn()
            } else {
                handleWaitingForTurn()
            }
        }
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        // Load 'GameScene.sks' as a SKScene. This provides gameplay-related content,
        // including entities and graphs.
        if let scene = GameScene(fileNamed: "GameScene") {
            scene.backgroundColor = .black

            // Set the scale mode to scale to fit the window.
            scene.scaleMode = .aspectFill

            // Present the scene.
            if let view = skInterface {
                view.presentScene(scene)
            }
        }

        if let connection = sharedConnection {
            // Take over being the connection delegate from the main view controller.
            connection.delegate = self
            handleTurn(connection.initiatedConnection)
        }
    
    }

    func stopGame() {
        if let connection = sharedConnection {
            connection.cancel()
        }
        sharedConnection = nil
        self.pop()
    }

    @IBAction func handleTap(sender: AnyObject) {
        if let tapGesture = sender as? WKTapGestureRecognizer {
            if tapGesture.numberOfTapsRequired == 1 {
                // Restart the game on a single tap only if presenting the congratulations screen.

                if let character = selectedFamily?.emojiArray().randomElement(),
                   let sceneView = skInterface,
                   let scene = sceneView.scene as? GameScene {
                    scene.updateSelectedRowColumn(tapGesture.locationInObject(), tapBounds: tapGesture.objectBounds())
                        if let column = scene.selectedColumn,
                            let row = scene.selectedRow {
                                scene.placeCharacter(character: character, column: column, row: row)
                                let move = String("\(character),\(column),\(row)")
                                sharedConnection?.sendMove(move)
                                self.handleTurn(false)
                        }
                }
            }
        }
    }
}

extension GameViewController: PeerConnectionDelegate {
    func connectionReady() {
        // Ignore, because the game is already playing in the main view controller.
    }
    func displayAdvertiseError(_ error: NWError) {
        // Ignore, because the game is already in progress.
    }

    func connectionFailed() {
        stopGame()
    }

    func receivedMessage(content: Data?, message: NWProtocolFramer.Message) {
        guard let content = content else {
            return
        }
        switch message.gameMessageType {
        case .invalid:
            print("Received invalid message")
        case .selectedCharacter:
            handleSelectCharacter(content, message)
        case .move:
            handleMove(content, message)
        }
    }

    func handleSelectCharacter(_ content: Data, _ message: NWProtocolFramer.Message) {
        // Handle the peer selecting a character family.
        if let character = String(data: content, encoding: .utf8) {
            peerSelectedFamily = GameCharacterFamily(character)
            handleTurn(true)
        }
    }

    func handleMove(_ content: Data, _ message: NWProtocolFramer.Message) {
        // Handle the peer placing a character on a given location.
        if let move = String(data: content, encoding: .utf8) {
            let portions = move.split(separator: ",")
            if portions.count == 3,
                let column = Int(portions[1]),
                let row = Int(portions[2]),
                0..<3 ~= column && 0..<3 ~= row,
                let sceneView = skInterface,
                let scene = sceneView.scene as? GameScene {
                scene.placeCharacter(character: String(portions[0]), column: column, row: row)
            }
            handleTurn(true)
        }
    }
}
