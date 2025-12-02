/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Background Assets app extension.
*/
import BackgroundAssets
import OSLog

extension Logger {
    static let ext = Logger(subsystem: "com.example.apple-samplecode.WWDC-Sessions",
                            category: "extension")
}

@main
struct BackgroundDownloadHandler: BADownloaderExtension {
    
    func downloads(for request: BAContentRequest,
                   manifestURL: URL,
                   extensionInfo: BAAppExtensionInfo) -> Set<BADownload> {
        
        let manifest: Manifest
        do {
            // Load the downloaded manifest and parse it to ensure its validity
            // Keep in mind that the `manifestURL` is read-only, and will be
            // deleted once this function exits scope.
            manifest = try Manifest.load(from: manifestURL)
            
            // Atomically save the parsed manifest to its final location
            // Note: Since this function performs an atomic replace, acquiring
            // exclusive control is not necessary
            try manifest.save(to: SharedSettings.localManifestURL)
            
        } catch {
            Logger.ext.error("Failed to load and replace manifest: \(error)")
            return []
        }
        
        // Essential downloads contribute to app installation progress, and
        // download with foreground priority. Therefore they are only enqueuable
        // during app-install or app-update.
        let essentialDownloadsPermitted = request == .install || request == .update
        
        // The final set of downloads to be scheduled.
        var downloadsToSchedule: Set<BADownload> = []
        
        // Iterate through the new manifest, enqueueing downloads for any sessions
        // that are not already present on the device.
        for session in manifest.sessions where session.state == .remote {
            let download = BAURLDownload(
                identifier: session.downloadIdentifier,
                request: URLRequest(url: session.URL),
                essential: session.essential && essentialDownloadsPermitted,
                fileSize: Int(session.fileSize),
                applicationGroupIdentifier: SharedSettings.appGroupIdentifier,
                priority: .default)
            
            Logger.ext.log("Enqueued download: \(download.identifier)")
            downloadsToSchedule.insert(download)
        }
        
        return downloadsToSchedule
    }

    func backgroundDownload(_ failedDownload: BADownload, failedWithError error: any Error) {
        // If the `BAManifestURL` fails to download, the extension is notified about it.
        // The type of the manifest is not a `BAURLDownload`, therefore you can key off of
        // the download's type to filter it out.
        guard type(of: failedDownload) == BAURLDownload.self else {
            Logger.ext.warning("Download of unsupported type failed: \(failedDownload.identifier). \(error)")
            return
        }
        
        // If the failed download is essential, it can be re-enqueued in the background
        // so that it may be downloaded at a later point in time.
        if failedDownload.isEssential {
            Logger.ext.warning("Rescheduling failed download: \(failedDownload.identifier). \(error)")
            do {
                let optionalDownload = failedDownload.removingEssential()
                try BADownloadManager.shared.scheduleDownload(optionalDownload)
            } catch {
                Logger.ext.warning("Failed to reschedule download \(failedDownload.identifier). \(error)")
            }
        } else {
            Logger.ext.warning("Download failed: \(failedDownload.identifier). \(error)")
        }
    }

    func backgroundDownload(_ finishedDownload: BADownload, finishedWithFileURL fileURL: URL) {
        
        // Since an asynchronous exclusive control is about to be invoked, the downloaded file must be
        // moved or else the system will delete it when this function exits scope.
        // To prevent this, the file is moved to a temporary location that the extension has access to.
        let ephemeralFileLocation: URL
        do {
            let temporaryDirectory = try FileManager.default.url(for: .itemReplacementDirectory,
                                                                 in: .userDomainMask,
                                                                 appropriateFor: SharedSettings.localManifestURL,
                                                                 create: true)
            ephemeralFileLocation = temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.moveItem(at: fileURL, to: ephemeralFileLocation)
        } catch {
            Logger.ext.error("Download finished, however a failure occurred moving the file to a temporary location. \(error)")
            return
        }
        
        // Asynchronously acquire exclusive control, this is to ensure that the app does not mutate
        // the manifest while the extension is reading from it.
        BADownloadManager.shared.withExclusiveControl { controlAcquired, error in
            // Always attempt to remove the ephemeral file location.
            // Although it's placed into a temporary directory anyway, deleting it immediately is better.
            defer {
                try? FileManager.default.removeItem(at: ephemeralFileLocation)
            }
            
            guard controlAcquired else {
                Logger.ext.warning("Failed to acquire lock: \(error)")
                return
            }

            // Fetch the most recently installed manifest.
            // This ensures that you always load the latest from either the app or the extension.
            let manifest: Manifest
            do {
                manifest = try Manifest.load(from: SharedSettings.localManifestURL)
            } catch {
                Logger.ext.error("Download finished, however the extension failed to load the most recent manifest. \(error)")
                return
            }
            
            // Grab the session from the loaded manifest that matches the download identifier
            guard let session = manifest.session(for: finishedDownload.identifier) else {
                Logger.ext.error("Download finished that is not referenced by the manifest: \(finishedDownload.identifier)")
                return
            }
            
            // Move the downloaded session from its ephemeral location to its final location
            do {
                try FileManager.default.moveItem(at: ephemeralFileLocation, to: session.fileURL)
            } catch {
                Logger.ext.error("Download finished, however the move from the ephemeral file location to the final destination failed. \(error)")
                return
            }
            
            // Verify the LocalSession has access to the file and is no longer `.remote`.
            let localSession = LocalSession(session: session)
            guard localSession.state == .downloaded else {
                Logger.ext.error("Download finished, however the LocalSession claims the file is not available.")
                return
            }
            
            Logger.ext.log("Download finished: \(finishedDownload.identifier)")
        }
    }
    
    func backgroundDownload(_ download: BADownload, didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        return (.performDefaultHandling, nil)
    }
}
