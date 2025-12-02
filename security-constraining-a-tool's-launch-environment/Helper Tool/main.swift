/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A command-line tool that adds two numbers it receives from a file handle.
*/
import Foundation

let input = try FileHandle(fileDescriptor: STDIN_FILENO).readToEnd()
let inputLines = String(data: input ?? Data(), encoding: .utf8)?.split(separator: "\n")
if let inputLines {
    if inputLines.count >= 2 {
        let firstNumber = Int(inputLines[0]) ?? 0
        let secondNumber = Int(inputLines[1]) ?? 0
        let result = firstNumber + secondNumber
        try FileHandle(fileDescriptor: STDOUT_FILENO).write(contentsOf: String(result).data(using: .utf8)!)
    }
}
