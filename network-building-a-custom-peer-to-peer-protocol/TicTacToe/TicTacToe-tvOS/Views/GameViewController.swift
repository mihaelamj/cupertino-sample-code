/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Build a view controller for Tic-Tac-Toe gameplay.
*/

import UIKit
import SpriteKit
import GameplayKit
import Network

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

class GameViewController: UITableViewController {

    @IBOutlet weak var sceneView: SKView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var resignLabel: UILabel!
    
    var selectedFamily: GameCharacterFamily?
    var peerSelectedFamily: GameCharacterFamily?

    func declareWinner(_ string: String) {
        if let sceneView = sceneView,
            let scene = sceneView.scene as? GameScene {
            scene.hideSelectSquares()
        }
        instructionLabel.text = string
        resignLabel.text = "Exit"
    }

    func handleMyTurnSelectFamily() {

        // Disable the family the peer selects.
        repeat {
            selectedFamily = GameCharacterFamily.allCases.randomElement()
        } while (selectedFamily == peerSelectedFamily)
        
        guard let character = selectedFamily!.emojiArray().first else {
            return
        }
        instructionLabel.text = "Selected Family: \(character)"
        sharedConnection?.selectCharacter(character)
        handleTurn(false)
    }

    func handleWaitingToSelectFamily() {
        instructionLabel.text = "Waiting for other player"
        
    }

    func handleMyTurn() {
        if let character = selectedFamily?.emojiArray().randomElement(),
            let sceneView = sceneView,
            let scene = sceneView.scene as? GameScene {
            scene.showSelectSquares()
            instructionLabel.text = "Taking my turn"
            
            DispatchQueue.global(qos: .background).async {
                if scene.selectedRow == nil {
                    scene.selectedRow = Int.random(in: 0..<3)
                    scene.selectedColumn = Int.random(in: 0..<3)
                    scene.updateSelectedRowColumn()
                    
                    sleep(1)
                 
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

    func handleWaitingForTurn() {
        if let sceneView = sceneView,
            let scene = sceneView.scene as? GameScene {
            scene.hideSelectSquares()
        }
        instructionLabel.text = "Waiting for other player"
    }

    func handleTurn(_ myTurn: Bool) {
        if let sceneView = sceneView,
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

    override func viewDidLoad() {
        super.viewDidLoad()

        instructionLabel.text = "Waiting for other player"

        // Load 'GameScene.sks' as a GKScene. This provides gameplay-related content,
        // including entities and graphs.
        if let scene = GKScene(fileNamed: "GameScene"),
            let sceneNode = scene.rootNode as? GameScene {
            sceneNode.backgroundColor = .white

            // Set the scale mode to scale to fit the window.
            sceneNode.scaleMode = .aspectFill

            // Present the scene.
            if let view = sceneView {
                view.presentScene(sceneNode)
                view.ignoresSiblingOrder = true
            }
        }

        if let connection = sharedConnection {
            // Take over being the connection delegate from the main view controller.
            connection.delegate = self
            handleTurn(connection.initiatedConnection)
        }
    
    }

    func stopGame() {
        if let sharedConnection = sharedConnection {
            sharedConnection.cancel()
        }
        sharedConnection = nil
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            stopGame()
        }
        tableView.deselectRow(at: indexPath, animated: true)
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
                let sceneView = sceneView,
                let scene = sceneView.scene as? GameScene {
                scene.placeCharacter(character: String(portions[0]), column: column, row: row)
            }
            handleTurn(true)
        }
    }
}
