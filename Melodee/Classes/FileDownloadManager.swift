//
//  FileDownloadManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2026/04/08.
//

import Foundation

@Observable
class FileDownloadManager {

    @ObservationIgnored private var metadataQuery: NSMetadataQuery?
    @ObservationIgnored private var observer: Any?
    @ObservationIgnored private var pollTimer: Timer?

    /// Map of file path → download progress (0.0 to 1.0), nil means no progress data yet
    var downloadProgress: [String: Double?] = [:]

    /// Callbacks to invoke when a specific file finishes downloading
    @ObservationIgnored private var completionHandlers: [String: () -> Void] = [:]

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func startDownload(for file: FSFile, onComplete: (() -> Void)? = nil) {
        let url = URL(filePath: file.path)
        if let onComplete {
            completionHandlers[file.path] = onComplete
        }
        downloadProgress[file.path] = .some(nil)
        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
        } catch {
            debugPrint("Failed to start downloading: \(error.localizedDescription)")
            downloadProgress.removeValue(forKey: file.path)
            completionHandlers.removeValue(forKey: file.path)
        }
    }

    func isDownloading(_ file: FSFile) -> Bool {
        return downloadProgress.keys.contains(file.path)
    }

    /// Returns the download progress (0.0–1.0), or nil if progress data is not yet available
    func progress(for file: FSFile) -> Double? {
        guard let entry = downloadProgress[file.path] else { return nil }
        return entry
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(value: true)

        observer = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: query,
            queue: .main
        ) { [weak self] notification in
            self?.handleQueryUpdate(notification)
        }

        metadataQuery = query
        query.start()

        // Poll for file existence as a reliable fallback for completion detection.
        // NSMetadataQuery paths may not match FSFile paths (due to .icloud stripping),
        // so polling ensures we detect when the real file appears on disk.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.pollForCompletedDownloads()
        }
    }

    private func stopMonitoring() {
        metadataQuery?.stop()
        pollTimer?.invalidate()
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func pollForCompletedDownloads() {
        for path in Array(downloadProgress.keys) {
            let fileURL = URL(filePath: path)
            // Check if the real file now exists on disk (not the .icloud placeholder)
            guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
                continue
            }
            // Verify it's actually downloaded via resource values if it's a ubiquitous item
            do {
                let values = try fileURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
                if let status = values.ubiquitousItemDownloadingStatus, status != .current {
                    continue
                }
            } catch {
                // Not a ubiquitous item or error reading - if the file exists, treat as downloaded
            }
            markCompleted(path: path)
        }
    }

    private func handleQueryUpdate(_ notification: Notification) {
        guard let query = metadataQuery else { return }
        query.disableUpdates()
        defer { query.enableUpdates() }

        for index in 0..<query.resultCount {
            guard let item = query.result(at: index) as? NSMetadataItem,
                  let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else {
                continue
            }

            // Only track files we've requested downloads for
            guard downloadProgress.keys.contains(path) else { continue }

            let percent = item.value(
                forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey
            ) as? Double

            let status = item.value(
                forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey
            ) as? String

            if let percent {
                downloadProgress[path] = min(percent / 100.0, 1.0)
            }

            if status == NSMetadataUbiquitousItemDownloadingStatusCurrent || (percent ?? 0.0) >= 100.0 {
                markCompleted(path: path)
            }
        }
    }

    private func markCompleted(path: String) {
        downloadProgress.removeValue(forKey: path)
        if let handler = completionHandlers.removeValue(forKey: path) {
            handler()
        }
    }
}
