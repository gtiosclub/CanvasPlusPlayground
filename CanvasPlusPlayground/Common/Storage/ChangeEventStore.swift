//
//  ChangeEventStore.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/31/26.
//

import Foundation

protocol ChangeEventStore: Sendable {
    /// Loads committed state or reports why no usable state exists.
    /// - Returns: The saved envelope or an empty-state recovery reason.
    func load() async throws -> ChangeStoreLoadResult

    /// Replaces committed state only when the entire save succeeds.
    /// - Parameter envelope: Complete state to persist atomically.
    func save(_ envelope: ChangeStoreEnvelope) async throws

    /// Moves unusable committed state aside so a later save cannot overwrite it.
    /// - Parameter timestamp: Time recorded in the quarantined copy's name.
    /// - Returns: Location of the quarantined copy, or nil when nothing was stored.
    @discardableResult
    func quarantine(timestamp: Date) async throws -> URL?
}

enum ChangeStoreLoadResult: Equatable, Sendable {
    case loaded(ChangeStoreEnvelope)
    case empty(RecoveryReason)

    enum RecoveryReason: Equatable, Sendable {
        case missing
        case corrupt
    }
}

enum ChangeStoreError: Error, Equatable, Sendable {
    case unsupportedFormat(Int)
}

actor JSONChangeEventStore: ChangeEventStore {
    static let defaultFileURL = URL.applicationSupportDirectory
        .appending(path: Bundle.main.bundleIdentifier ?? "CanvasPlusPlayground")
        .appending(path: "change-events.json")

    private let fileURL: URL

    /// Creates a store backed by one JSON file.
    /// - Parameter fileURL: Destination file. Tests supply an isolated temporary URL.
    init(
        fileURL: URL = JSONChangeEventStore.defaultFileURL
    ) {
        self.fileURL = fileURL
    }

    func load() async throws -> ChangeStoreLoadResult {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return .empty(.missing)
        }

        let header: FormatHeader
        do {
            header = try JSONDecoder().decode(FormatHeader.self, from: data)
        } catch {
            return .empty(.corrupt)
        }

        guard header.formatVersion <= ChangeStoreEnvelope.currentFormatVersion else {
            throw ChangeStoreError.unsupportedFormat(header.formatVersion)
        }
        guard header.formatVersion == ChangeStoreEnvelope.currentFormatVersion else {
            return .empty(.corrupt)
        }

        let envelope: ChangeStoreEnvelope
        do {
            envelope = try JSONDecoder().decode(ChangeStoreEnvelope.self, from: data)
            return .loaded(envelope)
        } catch {
            return .empty(.corrupt)
        }
    }

    func save(_ envelope: ChangeStoreEnvelope) async throws {
        guard envelope.formatVersion == ChangeStoreEnvelope.currentFormatVersion else {
            throw ChangeStoreError.unsupportedFormat(envelope.formatVersion)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(envelope)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    func quarantine(timestamp: Date) async throws -> URL? {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return nil }

        let stamp = timestamp.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
            .filter { $0.isLetter || $0.isNumber }
        let name = "\(fileURL.deletingPathExtension().lastPathComponent).corrupt-\(stamp).\(fileURL.pathExtension)"
        let destination = fileURL.deletingLastPathComponent().appending(path: name)
        try FileManager.default.moveItem(at: fileURL, to: destination)
        return destination
    }

    private struct FormatHeader: Decodable {
        let formatVersion: Int
    }
}
