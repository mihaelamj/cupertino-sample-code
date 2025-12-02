/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Unit tests for tree and forest types.
*/

import XCTest
@testable import Forest
@testable import ForestTestSupport

final class ForestTests: XCTestCase {
    func testBasics() throws {
        let palmTree = Tree(TreeKind.Palm, "Tommy")
        let redwoodTree = Tree(TreeKind.Redwood, "Cory")
        XCTAssertNotEqual(palmTree, redwoodTree)
    }
}
