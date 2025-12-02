/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A function that calls an external helper tool to add two numbers.
*/

import Foundation

func sum(firstNumber: Int, secondNumber: Int) throws -> Int {
    let inPipe = Pipe()
    let outPipe = Pipe()
    let helperTask = Process()
    helperTask.executableURL = Bundle.main.url(forAuxiliaryExecutable: "Helper Tool")
    helperTask.standardInput = inPipe
    helperTask.standardOutput = outPipe
    let firstInput = "\(firstNumber)\n".data(using: .utf8)!
    let secondInput = "\(secondNumber)\n".data(using: .utf8)!
    try helperTask.run()
    try inPipe.fileHandleForWriting.write(contentsOf: firstInput)
    try inPipe.fileHandleForWriting.write(contentsOf: secondInput)
    try inPipe.fileHandleForWriting.close()
    let taskOutput = try outPipe.fileHandleForReading.readToEnd()!
    return Int(String(data: taskOutput, encoding: .utf8) ?? "") ?? 0
}
