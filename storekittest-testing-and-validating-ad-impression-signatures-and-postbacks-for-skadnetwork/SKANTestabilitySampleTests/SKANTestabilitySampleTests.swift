/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The file containing your SKAdNetwork Unit Tests.
*/

import XCTest
import StoreKitTest
import StoreKit
@testable import SKANTestabilitySample

class SKANTestabilitySampleTests: XCTestCase {

    private var testSession: SKAdTestSession!

    private let publicKey = """
        MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEDizl6\
        HEGK3065O0xQrCl6pQehGCBoZStStmY+21UQgF3Lm\
        uERbaMDis1vJsEGpS/CCZtDzhvmoEvIilmtmvL9w==
        """

    override func setUpWithError() throws {
        testSession = SKAdTestSession()
        try super.setUpWithError()
    }

    /// Tests that a view-through ad impression is valid.
    func testImpressionValidity() throws {
        // Form the SKAdImpression instance and configure it.
        let impression = SKAdImpression()
        impression.version = "4.0"
        impression.adNetworkIdentifier = "com.apple.test-1"
        impression.sourceIdentifier = 3120
        impression.advertisedAppStoreItemIdentifier = 525_463_029
        impression.adImpressionIdentifier = "b7c9da2b-15c7-4f3b-9326-135f9630033d"
        impression.sourceAppStoreItemIdentifier = 0
        impression.timestamp = 1_676_057_605_705
        impression.signature = "MEQCIAtBBiadCFlMOEOh3K43xyKaU1/sj/CtgDOB+Wm7J+29AiBDfreX67mm4X9ZoM4xkHHLtuMM2OXcS5kQ7UpVb69A/Q=="

        try testSession.validate(impression, publicKey: publicKey)
    }

    /// Tests that a StoreKit-rendered ad parameter dictionary is valid.
    func testImpressionParametersValidity() throws {
        // Form the StoreKit-rendered ad parameter dictionary.
        let signature = "MEUCIQDKIV284QzOEBuYQYsyS0fJ2Im+vaBuTtOpncj1ieP5HAIgaAYbOi31mkYp6EUUj06AZodVmHdZhF7UrGe20tEaUMo="
        let parameters: [String: Any] = [
            SKStoreProductParameterAdNetworkVersion: "4.0",
            SKStoreProductParameterAdNetworkSourceIdentifier: 1540,
            SKStoreProductParameterITunesItemIdentifier: 525_463_029,
            SKStoreProductParameterAdNetworkIdentifier: "com.apple.test-1",
            SKStoreProductParameterAdNetworkNonce: "431a2487-3302-4ee7-9eb5-4243d4607672",
            SKStoreProductParameterAdNetworkTimestamp: 1_678_912_480_034,
            SKStoreProductParameterAdNetworkSourceAppStoreIdentifier: 0,
            SKStoreProductParameterAdNetworkAttributionSignature: signature
        ]

        try testSession.validateImpression(parameters: parameters, publicKey: publicKey)
    }

    /// Tests that a web ad impression payload is valid.
    func testWebAdImpressionPayloadValidity() throws {
        // Form the Web Ad Impression Payload data.
        let webAdImpressionPayloadJSON = """
        {
            "version": "4.0",
            "ad_network_id": "com.apple.test-1",
            "source_identifier": 3120,
            "itunes_item_id": 525463029,
            "nonce": "b7c9da2b-15c7-4f3b-9326-135f9630033d",
            "source_domain": "example.com",
            "timestamp": 1676057605705,
            "signature": "MEUCID/KZzaGxpa9jv9P1thWn8cHzcDq8ebDWEoarV1JrjNcAiEA6d9IqYErxFCrD96oR0rRftjVW6PRx37MC9QPS88OeE4="
        }
        """

        guard let webImpressionData = webAdImpressionPayloadJSON.data(using: .utf8) else {
            XCTFail("Failed to convert JSON to data.")
            return
        }

        try testSession.validateWebAdImpressionPayload(webImpressionData, publicKey: publicKey)
    }

    /// Adds three winning postbacks to a test session.
    func testAddingPostbacks() throws {
        guard let testPostbacks = SKAdTestPostback.winningPostbacks(withVersion: .version4_0,
                                                                    adNetworkIdentifier: "com.apple.test-1",
                                                                    sourceIdentifier: "3120",
                                                                    appStoreItemIdentifier: 0,
                                                                    sourceAppStoreItemIdentifier: 525_463_029,
                                                                    sourceDomain: nil,
                                                                    fidelityType: 1,
                                                                    isRedownload: false,
                                                                    postbackURL: "TEST SERVER ENDPOINT") else {
            XCTFail("Failed to create postbacks.")
            return
        }

        try testSession.setPostbacks(testPostbacks)
    }

    /// Tests updating the postback's conversion value in the test session.
    func testUpdatingPostback() throws {
        try setPostbacks()

        updatePostbackConversionValue()

        let fetchedPostbacks = testSession.postbacks
        guard fetchedPostbacks.count == 3 else {
            XCTFail("Expecting 3 postbacks, received \(fetchedPostbacks.count).")
            return
        }

        // A test session's `postbacks` property maintains the order of the postbacks.
        let firstPostback = fetchedPostbacks[0]
        XCTAssertEqual(firstPostback.fineConversionValue, 42)
    }

    /// Sends the registered postback to the remote server.
    func testSendingPostback() throws {
        try setPostbacks()
        
        updatePostbackConversionValue()

        testSession.flushPostbacks { responses, error in
            XCTAssertNil(error)
            guard let concreteResponses = responses else {
                XCTFail("No responses received.")
                return
            }
            for response in concreteResponses {
                let postbackResponse = response.value
                XCTAssertNil(postbackResponse.error)
                XCTAssertTrue(postbackResponse.didSucceed)
            }
        }
    }

    // MARK: - Utility

    private func setPostbacks() throws {
        guard let testPostbacks = SKAdTestPostback.winningPostbacks(withVersion: .version4_0,
                                                                    adNetworkIdentifier: "com.apple.test-1",
                                                                    sourceIdentifier: "3120",
                                                                    appStoreItemIdentifier: 0,
                                                                    sourceAppStoreItemIdentifier: 525_463_029,
                                                                    sourceDomain: nil,
                                                                    fidelityType: 1,
                                                                    isRedownload: false,
                                                                    postbackURL: "TEST SERVER ENDPOINT") else {
            XCTFail("Failed to create postbacks.")
            return
        }
        try testSession.setPostbacks(testPostbacks)
    }

    private func updatePostbackConversionValue() {
        let expectation = XCTestExpectation(description: "Update the postback's conversion value.")
        SKAdNetwork.updatePostbackConversionValue(42, coarseValue: .low) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation])
    }
}

