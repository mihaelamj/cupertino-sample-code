/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that add convenience methods to CloudKit.
*/

import Foundation
import CloudKit
import CoreTransferable

extension CKShare.ParticipantAcceptanceStatus {
    var stringValue: String {
        return ["Unknown", "Pending", "Accepted", "Removed"][rawValue]
    }
}

extension CKShare {
    var title: String {
        guard let date = creationDate else {
            return "\(UUID().uuidString)"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#if os(iOS) || os(macOS)
extension CKShare: Transferable {
    static public var transferRepresentation: some TransferRepresentation {
        CKShareTransferRepresentation { shareToExport in
            return .existing(shareToExport, container: PersistenceController.shared.cloudKitContainer)
        }
    }
}
#endif
