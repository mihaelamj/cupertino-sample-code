/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Example UI testing.
*/

import XCTest

class DemoUITests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        // In UI tests, it's usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testExample() throws {
        // UI tests need to launch the app that they test.
        let app = XCUIApplication()
        app.launch()

        // Use a recording to begin writing UI tests.
        // Use XCTAssert and related functions to verify that your tests produce expected results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your app.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
