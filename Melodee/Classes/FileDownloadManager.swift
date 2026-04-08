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

    /// Map of file path → download progress (0.0 to 1.0)
    var downloadProgress: [String: Double] = [:]

    /// Files that have completed downloading and are ready for use
    var completedPaths: Set<String> = []

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
        downloadProgress[file.path] = 0.0
        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
        } catch {
            debugPrint("Failed to start downloading: \(error.localizedDescription)")
            downloadProgress.removeValue(forKey: file.path)
            completionHandlers.removeValue(forKey: file.path)
        }
    }

    func isDownloading(_ file: FSFile) -> Bool {
        return downloadProgress[file.path] != nil && !completedPaths.contains(file.path)
    }

    func progress(for file: FSFile) -> Double {
        return downloadProgress[file.path] ?? 0.0
    }

    // MARK: - NSMetadataQuery monitoring

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
    }

    private func stopMonitoring() {
        metadataQuery?.stop()
        if let observer {
            NotificationCenter.default.removeObserver(observer)
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
            guard downloadProgress[path] != nil else { continue }

            let percent = item.value(
                forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey
            ) as? Double ?? 0.0

            let status = item.value(
                forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey
            ) as? String

            downloadProgress[path] = min(percent / 100.0, 1.0)

            if status == NSMetadataUbiquitousItemDownloadingStatusCurrent || percent >= 100.0 {
                completedPaths.insert(path)
                downloadProgress.removeValue(forKey: path)
                if let handler = completionHandlers.removeValue(forKey: path) {
                    handler()
                }
            }
        }
    }
}
