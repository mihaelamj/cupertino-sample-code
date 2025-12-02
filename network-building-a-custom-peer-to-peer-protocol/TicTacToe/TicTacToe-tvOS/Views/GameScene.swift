/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Define a SpriteKit scene for the Tic-Tac-Toe gameboard.
*/

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    private var boardLabels = [[SKLabelNode]]()
    private var boardSquares = [[SKShapeNode]]()

    var selectedColumn: Int?
    var selectedRow: Int?

    override func sceneDidLoad() {

        for _ in 0..<3 {
            boardLabels.append([SKLabelNode]())
            boardSquares.append([SKShapeNode]())
        }

        for column in 0..<3 {
            for row in 0..<3 {
                if let labelNode = childNode(withName: "Label,\(column),\(row)") as? SKLabelNode {
                    labelNode.text = ""
                    boardLabels[column].append(labelNode)
                }
                if let shapeNode = childNode(withName: "Square,\(column),\(row)") as? SKShapeNode {
                    boardSquares[column].append(shapeNode)
                }
            }
        }
        hideSelectSquares()
    }

    func showSelectSquares() {
        for column in 0..<3 {
            for row in 0..<3 {
                let labelNode = boardLabels[column][row]
                if labelNode.text?.isEmpty ?? true {
                    if column == selectedColumn && row == selectedRow {
                        boardSquares[column][row].fillColor = .systemGreen
                        boardSquares[column][row].strokeColor = .clear
                        boardSquares[column][row].lineWidth = 0
                    } else {
                        boardSquares[column][row].fillColor = .clear
                        boardSquares[column][row].strokeColor = .systemBlue
                        boardSquares[column][row].lineWidth = 4
                    }
                    boardSquares[column][row].alpha = 1.0
                }
            }
        }
    }

    func hideSelectSquares() {
        selectedColumn = nil
        selectedRow = nil
        for column in 0..<3 {
            for row in 0..<3 {
                boardSquares[column][row].alpha = 0.0
            }
        }
    }

    func placeCharacter(character: String, column: Int, row: Int) {
        if 0..<3 ~= column && 0..<3 ~= row {
            boardLabels[column][row].text = character
            boardSquares[column][row].alpha = 0.0
        }
    }

    func getWinner(_ squares: [(Int, Int)]) -> GameCharacterFamily? {
        var winningFamily: GameCharacterFamily? = nil
        for (column, row) in squares {
            guard let character = boardLabels[column][row].text else {
                // If no character is at the required location, fail.
                winningFamily = nil
                break
            }
            guard let family = GameCharacterFamily(character) else {
                // If the wrong character is at the required location, fail.
                winningFamily = nil
                break
            }
            if winningFamily == nil {
                // If this is the first location checked, remember the character.
                winningFamily = family
            } else if family != winningFamily {
                // If the characters don't match, fail.
                winningFamily = nil
                break
            }
        }
        if winningFamily != nil {
            return winningFamily
        }
        return nil
    }

    func getWinner() -> GameCharacterFamily? {
        let winningMoves: [[(Int, Int)]] =
            [ [ (0, 0), (0, 1), (0, 2) ],
              [ (1, 0), (1, 1), (1, 2) ],
              [ (2, 0), (2, 1), (2, 2) ],
              [ (0, 0), (1, 0), (2, 0) ],
              [ (0, 1), (1, 1), (2, 1) ],
              [ (0, 2), (1, 2), (2, 2) ],
              [ (0, 0), (1, 1), (2, 2) ],
              [ (2, 0), (1, 1), (0, 2) ] ]
        for move in winningMoves {
            if let winner = getWinner(move) {
                return winner
            }
        }
        return nil
    }

    func gameResult() -> GameResult {
        if let winningFamily = getWinner(),
            let winningCharacter = winningFamily.emojiArray().first {
            return GameResult.playerWon(character: winningCharacter)
        }

        var hasEmptySquares = false
        for column in 0..<3 {
            for row in 0..<3 {
                guard let character = boardLabels[column][row].text else {
                    hasEmptySquares = true
                    break
                }
                if GameCharacterFamily(character) == nil {
                    hasEmptySquares = true
                    break
                }
            }
        }

        if hasEmptySquares {
            return GameResult.inProgress
        } else {
            return GameResult.catsGame
        }
    }
    
    func updateSelectedRowColumn() {
        guard let column: Int = selectedColumn else {
            return
        }
        guard let row: Int = selectedRow else {
            return
        }
        if row < 2 {
            selectedRow = row + 1
        } else {
            selectedRow = 0
            if column < 2 {
                selectedColumn = column + 1
            } else {
                selectedColumn = 0
            }
        }
        if boardLabels[selectedColumn!][selectedRow!].text == "" {
            showSelectSquares()
        } else {
            updateSelectedRowColumn()
        }
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
}
