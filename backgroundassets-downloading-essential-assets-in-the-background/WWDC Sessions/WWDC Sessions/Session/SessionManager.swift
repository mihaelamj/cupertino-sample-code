/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages and downloads sessions.
*/

import Foundation
import OSLog
import UniformTypeIdentifiers
import Combine
import BackgroundAssets
import SwiftUI

final class SessionManager: NSObject, ObservableObject, @unchecked Sendable {
    
    var sessions: [LocalSession] {
        return Array(self.sessionSet).sorted {
            $0.id < $1.id
        }
    }
    
    @Published
    private var sessionSet = Set<LocalSession>()
    
    private var manifest = Manifest() {
        willSet {
            self.stateLock.lock()
        }
        didSet {
            self.stateLock.unlock()
        }
    }
    
    private let stateLock = NSLock()
    
    override init() {
        super.init()
        BADownloadManager.shared.delegate = self

        self.loadLocalManifest()
    }
    
    func delete(_ session: LocalSession) {
        try? FileManager.default.removeItem(at: session.fileURL)
        Task { @MainActor in
            self.stateLock.withLock {
                self.sessionSet.remove(session)
            }
        }
    }
    
    func refreshManifest() {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let manifestURLString = infoDictionary["BAManifestURL"] as? String,
              let manifestURL = URL(string: manifestURLString) else {
            Logger.app.error("Failed to retrieve manifest URL.")
            return
        }

        let downloadTask = URLSession.shared.downloadTask(with: manifestURL) { url, response, error in
            guard let url = url else {
                Logger.app.error("Manifest download failed. Response: \(response), error: \(error)")
                return
            }
            
            do {
                _ = try FileManager.default.replaceItemAt(SharedSettings.localManifestURL, withItemAt: url)
            } catch {
                Logger.app.error("Failed to move manifest: \(error)")
                return
            }
            
            self.loadLocalManifest()
        }
        
        downloadTask.resume()
    }
    
    private func updateDownloadProgress(_ session: LocalSession, progress: Double) {
        Task { @MainActor in
            session.downloadProgress = progress
        }
    }
    
    private func loadLocalManifest() {
        
        let localManifestURL = SharedSettings.localManifestURL
        let exists = FileManager.default.fileExists(atPath: SharedSettings.localManifestURL.path(percentEncoded: false))
        guard exists else {
            Logger.app.log("No remote manifest has been downloaded.")
            return
        }
        
        do {
            self.manifest = try Manifest.load(from: localManifestURL)
        } catch {
            Logger.app.error("Failed to load manifest: \(error)")
            return
        }
        
        Task { @MainActor in
            withAnimation {
                for session in self.manifest.sessions {
                    let shouldContinue = self.stateLock.withLock {
                        // If you already have this session, skip it.
                        if self.sessionSet.contains(session) {
                            return true
                        }
                        
                        self.sessionSet.insert(session)
                        return false
                    }
                    if shouldContinue {
                        continue
                    }
                    
                    // Start downloading the new session if necessary.
                    if session.state == .remote {
                        self.startDownload(of: session)
                    }
                }
            }
        }
    }

    func startDownload(of session: LocalSession) {
        BADownloadManager.shared.withExclusiveControl { lockAcquired, error in
            guard lockAcquired else {
                Logger.app.warning("Failed to acquire lock: \(error)")
                return
            }
            
            do {
                let download: BADownload
                let currentDownloads = try BADownloadManager.shared.fetchCurrentDownloads()
                
                // If this session is already being downloaded, promote it to the foreground.
                if let existingDownload = currentDownloads.first(where: { $0.identifier == session.downloadIdentifier }) {
                    download = existingDownload
                } else {
                    download = BAURLDownload(
                        identifier: session.downloadIdentifier,
                        request: URLRequest(url: session.URL),
                        essential: false,
                        fileSize: Int(session.fileSize),
                        applicationGroupIdentifier: SharedSettings.appGroupIdentifier,
                        priority: .default)
                }
                
                guard download.state != .failed else {
                    Logger.app.warning("Download for session \(session.id) is in the failed state.")
                    return
                }
                
                try BADownloadManager.shared.startForegroundDownload(download)
            } catch {
                Logger.app.warning("Failed to start download for session \(session.id): \(error)")
            }
        }
    }
}

// MARK: BADownloadManagerDelegate
extension SessionManager: BADownloadManagerDelegate {
    func download(_ download: BADownload,
                  didWriteBytes bytesWritten: Int64,
                  totalBytesWritten: Int64,
                  totalBytesExpectedToWrite totalExpectedBytes: Int64) {
        // Ignore `BAManifestURL` downloads while handling progress.
        guard type(of: download) == BAURLDownload.self else {
            return
        }

        guard let session = self.manifest.session(for: download.identifier) else {
            Logger.app.warning("Unknown download: \(download.identifier)")
            return
        }
        
        let progress = Double(totalBytesWritten) / Double(totalExpectedBytes)
        updateDownloadProgress(session, progress: progress)
    }
    
    func download(_ download: BADownload, finishedWithFileURL fileURL: URL) {
        guard let session = self.manifest.session(for: download.identifier) else {
            Logger.app.warning("Unknown download: \(download.identifier)")
            return
        }
        
        do {
            _ = try FileManager.default.replaceItemAt(session.fileURL, withItemAt: fileURL)
        } catch {
            Logger.app.error("Failed to move downloaded file: \(error)")
            return
        }
        
        Task { @MainActor in
            session.state = .downloaded
            await session.fetchThumbnail()
        }
    }
    
    func download(_ download: BADownload, failedWithError error: any Error) {
        // If the `BAManifestURL` fails to download, the BADownloadManager's delegate is notified about it.
        // The type of the manifest is not a `BAURLDownload`, therefore you can key off of
        // the download's type to filter it out.
        guard type(of: download) == BAURLDownload.self else {
            Logger.app.warning("Download of unsupported type failed: \(download.identifier). \(error)")
            return
        }

        guard self.manifest.session(for: download.identifier) != nil else {
            Logger.app.warning("Unknown download: \(download.identifier)")
            return
        }
        
        Logger.app.warning("Download failed: \(error)")
    }
    
    func download(_ download: BADownload, didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        return (.performDefaultHandling, nil)
    }
}
