/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model that supports the document reader user interface.
*/

import Foundation
import ProximityReader

@MainActor
final class ContentViewModel: ObservableObject {

    private var cachedSession: MobileDocumentReaderSession?

    func verifyButtonTapped() {
        Task {
            // Check that the device supports mobile document reading.
            guard MobileDocumentReader.isSupported else {
                // This device doesn't support the Verifier API.
                return
            }

            do {
                // Request the identity document elements.
                let response = try await self.verifyIdentity()

                // Verify the identity document elements.
                verifyDocumentElements(response.documentElements)
            } catch MobileDocumentReaderError.cancelled {
                // The user dismissed the document reader user interface.
            } catch {
                print("An error occurred while reading a mobile document: \(error.localizedDescription)")
            }
        }
    }

    private func verifyIdentity() async throws -> MobileDriversLicenseDataRequest.Response {
        // Create a driver's license display request containing the age over 21 element.
        let request = MobileDriversLicenseDataRequest(
            retainedElements: [.givenName, .familyName, .dateOfBirth, .portrait, .address],
            nonRetainedElements: [.documentNumber, .documentIssueDate, .documentExpirationDate, .drivingPrivileges]
        )

        // Perform the request using a previously cached reader session, if present.
        // If the cached session has expired, prepare the device for document reading again.
        if let cachedSession = self.cachedSession {
            do {
                return try await cachedSession.requestDocument(request)
            } catch MobileDocumentReaderError.sessionExpired {
                self.cachedSession = nil
            }
        }

        // To prepare the device for document reading, first create a mobile document reader object.
        let reader = MobileDocumentReader()

        // Then, send the reader instance identifier to your server in exchange for a reader token.
        let readerIdentifier = try await reader.configuration.readerInstanceIdentifier
        let tokenString = try await WebService().fetchToken(for: readerIdentifier)

        // Then, call `prepare`. If successful, cache the returned reader session object.
        // Your app can also cache the reader token string after a successful `prepare` call to support offline reading.
        let readerSession = try await reader.prepare(using: .init(tokenString))
        self.cachedSession = readerSession

        // Finally, request the document again with the newly created session.
        return try await readerSession.requestDocument(request)
    }

    private func verifyDocumentElements(_ documentElements: MobileDriversLicenseDataRequest.Response.DocumentElements) {
        print(documentElements)
    }

}
