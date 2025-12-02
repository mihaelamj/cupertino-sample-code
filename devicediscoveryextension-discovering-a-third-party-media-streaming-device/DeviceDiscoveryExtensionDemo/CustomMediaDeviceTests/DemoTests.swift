/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Example unit tests.
*/

import XCTest
@testable import DataAccessDemoClient

class DataAccessDemoTests: XCTestCase {

    override func setUpWithError() throws {
		try super.setUpWithError()
    }

    override func tearDownWithError() throws {
		try super.tearDownWithError()
    }

    func testExample() throws {
        // The sample app intentionally leaves this implementation blank.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testMessageParsing() throws {
        let clientMessage: DemoClientMessage = DemoClientMessage.fromJson(data: """
            {
                "messageType" : "SETVOLUME",
                "VOLUME" : {
                    "MUTED" : false,
                    "LEVEL" : 0.5
                }
            }
            """.data(using: .utf8)!)
        XCTAssertEqual(clientMessage.messageType, .setVolume)
        let volume = clientMessage.params["VOLUME"] as? [String: Any]
        let muted = volume!["MUTED"] as? Bool
        XCTAssertEqual(muted!, false)
    }

}
