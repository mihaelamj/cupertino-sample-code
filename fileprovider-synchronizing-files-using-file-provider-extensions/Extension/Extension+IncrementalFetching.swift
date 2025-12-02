/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Adds incremental fetching to the extension.
*/

import os.log
import Common
import FileProvider

private let fileChunker = FileChunker()

extension Extension: NSFileProviderIncrementalContentFetching {
    private struct ExistingChecksumAndMemoryMappedFile {
        let existingChecksums: [RangeAndSha256]
        let memoryMappedFile: Data
    }

    public func fetchContents(for itemIdentifier: NSFileProviderItemIdentifier,
                              version requestedVersion: NSFileProviderItemVersion?,
                              usingExistingContentsAt existingContents: URL,
                              existingVersion: NSFileProviderItemVersion,
                              request: NSFileProviderRequest,
                              completionHandler: @escaping (URL?, NSFileProviderItem?, Error?) -> Void) -> Progress {
        logger.info("Starting to incrementally fetch content for item: \(String(describing: itemIdentifier))")

        let progress = Progress(totalUnitCount: 110)

        // Retrieve the chunks, which exist from the new version of the item
        // (using its metadata). Verify that the version from self.item
        // matches the requestedVersion.
        let itemProgress = self.item(for: itemIdentifier, request: request) { itemOptional, errorOptional in
            if let error = errorOptional {
                self.logger.error("Error retrieving metadata about item: \(String(describing: itemIdentifier))")
                completionHandler(nil, nil, error)
                return
            }

            guard let item = itemOptional else {
                self.logger.error("Could not find metadata for item: \(String(describing: itemIdentifier))")
                completionHandler(nil, nil, CommonError.internalError)
                return
            }

            if let requestedVersion = requestedVersion {
                guard item.itemVersion == requestedVersion else {
                    self.logger.error("Could not incrementally fetch due to item version mismatch. Falling back to full fetch.")
                    self.logger.error("item.itemVersion = \(String(describing: item.itemVersion)), requestedVersion = \(String(describing: requestedVersion))")
                    // Directly fetch the file. You can't do this incrementally because
                    // the metadata is only available for a different version than
                    // the one you request.
                    let fetchProgress = self.fetchContents(for: itemIdentifier, version: requestedVersion, request: request,
                                                           completionHandler: completionHandler)
                    progress.addChild(fetchProgress, withPendingUnitCount: 95)
                    return
                }
            }

            guard let itemCasted = item as? Item else {
                self.logger.error("Could not cast item to Item class, identifier: \(String(describing: itemIdentifier))")
                completionHandler(nil, nil, CommonError.internalError)
                return
            }

            self.retrieveContentStorageType(itemIdentifier: itemCasted.entry.id,
                                            requestedRevision: itemCasted.entry.revision) { contentStorageTypeOptional, errorOptional in
                if let error = errorOptional as NSError? {
                    self.logger.error("Error retrieving content storage type for id \"\(itemCasted.entry.id)\": \(error)")
                    completionHandler(nil, nil, error)
                    return
                }

                guard let contentStorageType = contentStorageTypeOptional else {
                    self.logger.error("Expected to retrieve content storage type when no error, but didn't. Item id \"\(itemCasted.entry.id)\"")
                    completionHandler(nil, nil, CommonError.internalError)
                    return
                }

                let chunkingCompletionHandler = {
                    (url: URL?, item: NSFileProviderItem?, range: NSRange?, error: Error?) -> Void in
                    let forkProgress = self.fetchResourceFork(sourceItem: itemCasted, url: url, item: item, error: error,
                                                              completionHandler: completionHandler)
                    if let forkProgress = forkProgress {
                        progress.addChild(forkProgress, withPendingUnitCount: 10)
                    }
                }

                let fetchProgress: Progress
                switch contentStorageType {
                case .inline:
                    self.logger.info("Incremental fetch requested, but file was inline, so doing full fetch.")
                    // Directly fetch the file. This can't be incremental.
                    fetchProgress = self.fetchContents(for: itemIdentifier, version: requestedVersion, request: request,
                                                       completionHandler: completionHandler)
                case .inChunkStore(let contentSha256sOfDataChunks):
                    self.logger.info("Incremental fetch requested, working on it")
                    // Construct the new file with chunks of the original file on disk
                    // and chunks of the new version from the server. Find chunks
                    // of the original file that match by computing the SHA hash,
                    // finding the range of matching hashes, and copying that
                    // range to the new file.

                    fetchProgress = self.fetchContentsFromChunkStore(contentSha256S: contentSha256sOfDataChunks, item: item,
                                                                     previousVersionFileURL: existingContents,
                                                                     completionHandler: chunkingCompletionHandler)

                case .resourceFork:
                    fatalError("Should not happen")
                }
                progress.addChild(fetchProgress, withPendingUnitCount: 95)
            }
        }

        progress.addChild(itemProgress, withPendingUnitCount: 5)

        return progress
    }

    func fetchContentsFromChunkStore(contentSha256S: Common.DomainService.ContentSha256S,
                                     item: NSFileProviderItem,
                                     previousVersionFileURL: URL?,
                                     completionHandler:
                                     @escaping (URL?, NSFileProviderItem?, NSRange?, Error?) -> Void) -> Progress {
        let progressForEachChunk: Int64 = 100
        let progress = Progress(totalUnitCount: Int64(Int64(contentSha256S.hashList.count) * progressForEachChunk))

        fetchChunkQueue.async {
            let dataURL = self.makeTemporaryURL("fetchedContentsFromChunkStore")

            do {
                // In case of a 0 byte file, create the file.
                try Data().append(fileURL: dataURL)

                let existingChecksumAndMemoryMappedFile: ExistingChecksumAndMemoryMappedFile?
                if let previousVersionFileURL = previousVersionFileURL {
                    // Retrieve the chunks that exist from the original version of
                    // the item.
                    let memoryMappedFileData = try ChecksumComputer.memoryMapFile(file: previousVersionFileURL)
                    let chunks = try fileChunker.chunkData(data: memoryMappedFileData)
                    let existingChecksums = ChecksumComputer.computeSha256OfDataChunks(data: memoryMappedFileData, chunks: chunks)
                    existingChecksumAndMemoryMappedFile = ExistingChecksumAndMemoryMappedFile(existingChecksums: existingChecksums,
                                                                                              memoryMappedFile: memoryMappedFileData)
                } else {
                    existingChecksumAndMemoryMappedFile = nil
                }

                try contentSha256S.hashList.forEach { contentSha256 in
                    if let existingChecksumAndMemoryMappedFile = existingChecksumAndMemoryMappedFile {
                        let existingChecksum = existingChecksumAndMemoryMappedFile.existingChecksums.first { $0.sha256 == contentSha256 }

                        if let existingChecksum = existingChecksum {
                            // This chunk is already available in a local file.
                            // Copy the range of the file locally.

                            let memoryMappedFile = existingChecksumAndMemoryMappedFile.memoryMappedFile

                            let chunkData = memoryMappedFile.subdata(in: existingChecksum.range.startIndex..<existingChecksum.range.endIndex)

                            try chunkData.append(fileURL: dataURL)

                            let chunkProgress = Progress(totalUnitCount: 100)
                            chunkProgress.completedUnitCount = 100
                            progress.addChild(chunkProgress, withPendingUnitCount: progressForEachChunk)

                            return
                        }
                    }

                    let param: DomainService.GetDataChunkParameter
                    param = DomainService.GetDataChunkParameter(hexEncodedSha256OfData: contentSha256)
                    let semaphore = DispatchSemaphore(value: 0)
                    let chunkProgress = self.connection.makeJSONCallWithReturn(param) { result in
                        defer {
                            semaphore.signal()
                        }
                        do {
                            switch result {
                            case .failure(let error):
                                completionHandler(nil, nil, nil, error)
                                return
                            case .success((_, let chunkData)):
                                guard !chunkData.isEmpty else {
                                    self.logger.error("Received success response for GetDataChunk, but the data count was <= 0, identifier: \(String(describing: item.itemIdentifier))")
                                    completionHandler(nil, nil, nil, CommonError.internalError)
                                    return
                                }
                                try chunkData.append(fileURL: dataURL)
                            }
                        } catch {
                            completionHandler(nil, nil, nil, error)
                            return
                        }
                    }
                    progress.addChild(chunkProgress, withPendingUnitCount: progressForEachChunk)
                    semaphore.wait()
                }

                completionHandler(dataURL, item, nil, nil)
            } catch let error {
                completionHandler(nil, nil, nil, error)
                return
            }
        }

        return progress
    }

    func uploadFileInChunks(contents: URL) async throws -> (chunkSha256s: [RangeAndSha256], contentLength: Int64) {
        let chunks = try fileChunker.chunkFile(file: contents)
        let chunkSha256s = try ChecksumComputer.computeSha256OfFileChunks(file: contents, chunks: chunks)
        let setOfChunkSha256s: Set<String> = Set(chunkSha256s.map { (arg0) -> String in
            return arg0.sha256
        })
        let data = try ChecksumComputer.memoryMapFile(file: contents)
        assert(chunks.count == chunkSha256s.count)
        let contentLength = Int64(data.count)

        // Only upload the necessary chunks.
        self.logger.info("Kicking off upload of chunks")
        let checkChunksExistParam = DomainService.CheckChunkExistsParameter(hexEncodedSha256OfChunksToCheck: setOfChunkSha256s)
        let resp = try await connection.makeJSONCall(checkChunksExistParam)
        self.logger.info("Skipping upload of chunks which were already on the server: \(resp.chunksThatExist)")
        self.logger.info("Starting upload of chunks which were not on server: \(resp.chunksThatDoNotExist)")
        try await self.uploadRequiredChunks(resp: resp, chunks: chunkSha256s, data: data)
        self.logger.info("Completed uploading chunks which were not on server: \(resp.chunksThatDoNotExist)")

        return (chunkSha256s, contentLength)
    }

    func uploadRequiredChunks(resp: DomainService.CheckChunkExistsReturn,
                              chunks: [RangeAndSha256],
                              data: Data) async throws {
        // This uploads each chunk in series, though it is more efficient
        // to upload chunks in parallel (bounded, to not overload the system
        // when attempting to upload large files).
        for chunkSha256 in resp.chunksThatDoNotExist {
            guard let indexOfChunkInOriginalArray = chunks.firstIndex(where: { (arg0) -> Bool in
                return chunkSha256 == arg0.sha256
            }) else {
                fatalError("Could not find sha256 index which should exist, sha256: \(chunkSha256), list: \(chunks)")
            }
            let chunk = chunks[indexOfChunkInOriginalArray]
            let chunkData = data.subdata(in: chunk.range)
            _ = try await self.connection.makeJSONCall(DomainService.CreateDataChunkParameter(hexEncodedSha256OfData: chunkSha256), chunkData)
        }
    }
}

private extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer { try? fileHandle.close() }
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
