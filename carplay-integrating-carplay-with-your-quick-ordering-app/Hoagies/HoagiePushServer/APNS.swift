/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages the connection with Apple to send Live Activity updates.
*/

import Foundation
import CryptoKit

final class APNS {
    
    private struct Header: Encodable {
        let alg = "ES256"
        let kid = APNS.keyIdentifier
    }

    private struct Payload: Encodable {
        let iat = Int(Date().timeIntervalSince1970)
        let iss = APNS.teamIdentifier
    }
    
    private static let apnsTopic = "<Bundle ID>.push-type.liveactivity"
    
    private static let privateKey = """
    Enter Private key as PEM here
    """
    
    private static let keyIdentifier = "<Key ID from your developer account>"
    private static let teamIdentifier = "<Team ID from your developer account>"
    
    private static let lastTokenCreationDate = "lastSavedTokenDate"
    private static let savedTokenKey = "savedToken"
    
    /// - Tag: jwt
    private static func createJWT() throws -> String {
        if TestHoagieData.hoagieDefaults.string(forKey: savedTokenKey) == nil {
            let symKey = try P256.Signing.PrivateKey(pemRepresentation: privateKey)
            let headerJSONData = try JSONEncoder().encode(Header())
            let headerBase64String = headerJSONData.urlSafeBase64EncodedString()
            let payloadJSONData = try JSONEncoder().encode(Payload())
            let payloadBase64String = payloadJSONData.urlSafeBase64EncodedString()
            let toSign = Data((headerBase64String + "." + payloadBase64String).utf8)
            let signature = try symKey.signature(for: toSign)
            let signatureBase64String = signature.rawRepresentation.urlSafeBase64EncodedString()
            let token = [headerBase64String, payloadBase64String, signatureBase64String].joined(separator: ".")
            TestHoagieData.hoagieDefaults.set(Date.now, forKey: lastTokenCreationDate)
            TestHoagieData.hoagieDefaults.set(token, forKey: savedTokenKey)
            print(token)
            return token
        } else if
            let savedDate = TestHoagieData.hoagieDefaults.object(forKey: lastTokenCreationDate) as? Date,
            Date.now.timeIntervalSince(savedDate) > TestHoagieData.tenMinutes {
            TestHoagieData.hoagieDefaults.set(nil, forKey: lastTokenCreationDate)
            TestHoagieData.hoagieDefaults.set(nil, forKey: savedTokenKey)
            return try createJWT()
        } else if let token = TestHoagieData.hoagieDefaults.string(forKey: savedTokenKey) {
            print(token)
            return token
        } else {
            fatalError()
        }
    }
    
    private static func createHeaders() throws -> [String: String] {
        [
            "content-type": "application/json",
            "user-agent": "APNS/swift-nio",
            "apns-push-type": "liveactivity",
            "apns-priority": "\(10)",
            "apns-topic": apnsTopic,
            "authorization": "Bearer \(try createJWT())"
        ]
    }
    
    private static func eventforFlags(confirmed: Bool, preparing: Bool, ready: Bool, pickedUp: Bool) -> String {
        pickedUp == true ? "end" :
        ready == true ? "update" :
        preparing == true ? "update" :
        confirmed == true ? "start" : ""
    }
    
    private static func createAPS(
        confirmed: Bool,
        preparing: Bool,
        ready: Bool,
        pickedUp: Bool,
        order: TestHoagieData.HoagieOrder = TestHoagieData.houseFavoriteOrder()) -> [String: Any] {
        return [
                "aps": [
                    "event": eventforFlags(confirmed: confirmed, preparing: preparing, ready: ready, pickedUp: pickedUp),
                    "timestamp": Date().timeIntervalSince1970,
                    "dismissal-date": Int(Date().timeIntervalSince1970).advanced(by: Int(TestHoagieData.tenMinutes)),
                    "content-state": [
                        "isConfirmed": confirmed,
                        "isPreparing": preparing,
                        "isReady": ready,
                        "isPickedUp": pickedUp],
                    "attributes-type": "OrderStatusAttributes",
                    "attributes":
                        [
                        "isConfirmed": confirmed,
                        "isPreparing": preparing,
                        "isReady": ready,
                        "isPickedUp": pickedUp],
                        "hoagieOrder": [
                            "date": Date.timeIntervalSinceReferenceDate,
                            "order": order.order,
                            "type": order.type,
                            "pickupLocation": order.pickupLocation
                        ]
                ]
        ]
    }
    
    static func sendLiveActivityContent(
        token: String,
        confirmed: Bool,
        preparing: Bool,
        ready: Bool,
        pickedUp: Bool,
        order: TestHoagieData.HoagieOrder? = nil) async throws {
            var req = URLRequest(url: URL(string: "https://api.sandbox.push.apple.com:443/3/device/\(token)")!)
            req.allHTTPHeaderFields = try createHeaders()
            req.httpMethod = "POST"
            req.httpBody = try! JSONSerialization.data(
                withJSONObject: createAPS(confirmed: confirmed, preparing: preparing, ready: ready, pickedUp: pickedUp))
            let resp = try await URLSession.shared.data(for: req)
            print(resp.1)
    }
}
