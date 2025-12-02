/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that contains and manages locally stored app data.
*/

import Foundation
import ExposureNotification

struct Exposure: Codable {
    let date: Date
}

struct TestResult: Codable {
    var id: UUID                // A unique identifier for this test result
    var isAdded: Bool           // Whether the user completed the add positive diagnosis flow for this test result
    var dateAdministered: Date  // The date the test was administered
    var isShared: Bool          // Whether diagnosis keys were shared with the Health Authority for the purpose of notifying others
}

@propertyWrapper
class Persisted<Value: Codable> {
    
    init(userDefaultsKey: String, notificationName: Notification.Name, defaultValue: Value) {
        self.userDefaultsKey = userDefaultsKey
        self.notificationName = notificationName
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                wrappedValue = try JSONDecoder().decode(Value.self, from: data)
            } catch {
                wrappedValue = defaultValue
            }
        } else {
            wrappedValue = defaultValue
        }
    }
    
    let userDefaultsKey: String
    let notificationName: Notification.Name
    
    var wrappedValue: Value {
        didSet {
            
            do {
                let valueToEncode = try JSONEncoder().encode(wrappedValue)
                UserDefaults.standard.set(valueToEncode, forKey: userDefaultsKey)
            } catch {
                
            }
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }
    
    var projectedValue: Persisted<Value> { self }
    
    func addObserver(using block: @escaping () -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
            block()
        }
    }
}
class LocalStore {
    
    static let shared = LocalStore()
    
    @Persisted(userDefaultsKey: "isOnboarded", notificationName: .init("LocalStoreIsOnboardedDidChange"), defaultValue: false)
    var isOnboarded: Bool
    
    @Persisted(userDefaultsKey: "nextDiagnosisKeyFileIndex", notificationName: .init("LocalStoreNextDiagnosisKeyFileIndexDidChange"), defaultValue: 0)
    var nextDiagnosisKeyFileIndex: Int
    
    @Persisted(userDefaultsKey: "exposures", notificationName: .init("LocalStoreExposuresDidChange"), defaultValue: [])
    var exposures: [Exposure]
    
    @Persisted(userDefaultsKey: "dateLastPerformedExposureDetection",
               notificationName: .init("LocalStoreDateLastPerformedExposureDetectionDidChange"), defaultValue: nil)
    var dateLastPerformedExposureDetection: Date?
    
    @Persisted(userDefaultsKey: "exposureDetectionErrorLocalizedDescription", notificationName:
        .init("LocalStoreExposureDetectionErrorLocalizedDescriptionDidChange"), defaultValue: nil)
    var exposureDetectionErrorLocalizedDescription: String?
    
    @Persisted(userDefaultsKey: "testResults", notificationName: .init("LocalStoreTestResultsDidChange"), defaultValue: [:])
    var testResults: [UUID: TestResult]
}
