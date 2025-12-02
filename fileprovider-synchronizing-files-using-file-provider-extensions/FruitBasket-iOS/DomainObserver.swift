/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observer that lists all logged-in domains.
*/

import Foundation
@preconcurrency import FileProvider
import os.log

class DomainObserver: ObservableObject {
    struct DomainEntry: Identifiable, Hashable, Equatable, Sendable {
        init(domain: NSFileProviderDomain) {
            self.domain = domain
        }

        var id: NSFileProviderDomainIdentifier {
            return domain.identifier
        }
        let domain: NSFileProviderDomain

        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.id == rhs.id
        }
    }

    @MainActor @Published var domains = [DomainEntry]()
    var notificationTask: Task<Void, Never>!
    let logger = Logger(subsystem: "com.example.FruitBasket", category: "domain-observer")

    init() {
        notificationTask = Task {
            for await _ in NotificationCenter.default.notifications(named: .fileProviderDomainDidChange, object: nil) {
                do {
                    try await updateDomains()
                } catch let error {
                    self.logger.error("domain enumeration failed: \(error.localizedDescription)")
                }
            }
            fatalError("ran out of notifications")
        }
        // The initial update task.
        Task {
            do {
                try await updateDomains()
            } catch let error {
                fatalError("failed to run initial updateDomains: \(error.localizedDescription)")
            }
        }
    }

    func addDomain(displayName: String, accountIdentifier: String) {
        
        let domain = NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier(rawValue: accountIdentifier), displayName: displayName)
        NSFileProviderManager.add(domain) { _ in }
    }

    func removeDomain(_ entry: DomainEntry) {
        NSFileProviderManager.remove(entry.domain) { _ in }
    }

    private func updateDomains() async throws {
        let domains = try await NSFileProviderManager.domains().compactMap({ domain -> DomainEntry? in
            if domain.identifier.rawValue == "NSFileProviderDomainDefaultIdentifier" {
                return nil
            }
            return DomainEntry(domain: domain)
        })
        await MainActor.run {
            self.domains = domains
        }
    }
}
