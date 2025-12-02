/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents errors raised by the browser engine.
*/

public struct BrowserEngineError: Error {
  public var description: String
  public init(_ description: String) {
    self.description = description
  }
}
