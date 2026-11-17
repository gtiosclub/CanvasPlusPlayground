//
//  AgentStore.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/19/26.
//

import Foundation
import SwiftData

typealias IndexedChunk = AgentSchemaV1.IndexedChunk

// Derived data lives in its own store so it can be wiped and rebuilt without touching CanvasSchema.
enum AgentSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [IndexedChunk.self]
    }
}

enum AgentMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AgentSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

extension AgentSchemaV1 {
    @Model
    final class IndexedChunk {
        #Unique<IndexedChunk>([\.sourceID, \.ordinal])
        #Index<IndexedChunk>([\.sourceID], [\.courseID])

        var sourceID: String
        var courseID: String?
        var ordinal: Int
        var headingPath: [String]
        var text: String
        var contentHash: String
        /// `IndexSource.revision` at the time this row was written.
        var sourceRevision: String?
        /// `vectorCount` vectors of Float32, concatenated.
        var vectorData: Data
        var vectorCount: Int
        var modelIdentifier: String
        var modelRevision: Int
        var indexedAt: Date

        init(chunk: TextChunk, courseID: String?, sourceRevision: String?, vectorData: Data, vectorCount: Int, modelVersion: ChunkEmbedder.ModelVersion) {
            sourceID = chunk.sourceID
            self.courseID = courseID
            self.sourceRevision = sourceRevision
            ordinal = chunk.ordinal
            headingPath = chunk.headingPath
            text = chunk.text
            contentHash = chunk.contentHash
            self.vectorData = vectorData
            self.vectorCount = vectorCount
            modelIdentifier = modelVersion.identifier
            modelRevision = modelVersion.revision
            indexedAt = .now
        }

        func update(chunk: TextChunk, courseID: String?, sourceRevision: String?, vectorData: Data, vectorCount: Int, modelVersion: ChunkEmbedder.ModelVersion) {
            self.courseID = courseID
            self.sourceRevision = sourceRevision
            headingPath = chunk.headingPath
            text = chunk.text
            contentHash = chunk.contentHash
            self.vectorData = vectorData
            self.vectorCount = vectorCount
            modelIdentifier = modelVersion.identifier
            modelRevision = modelVersion.revision
            indexedAt = .now
        }

        func isEmbedded(by modelVersion: ChunkEmbedder.ModelVersion) -> Bool {
            modelIdentifier == modelVersion.identifier && modelRevision == modelVersion.revision
        }

        var vectors: [[Float]] {
            IndexedChunk.decode(vectorData, count: vectorCount)
        }

        /// - Parameter vectors: Vectors of equal length. Empty vectors (from `ChunkEmbedder.pool`) are dropped.
        /// - Returns: The non-empty vectors as concatenated Float32 bytes, and how many there are.
        static func encode(_ vectors: [[Float]]) -> (data: Data, count: Int) {
            let nonEmpty = vectors.filter { !$0.isEmpty }
            var data = Data(capacity: nonEmpty.reduce(0) { $0 + $1.count } * MemoryLayout<Float>.stride)
            for vector in nonEmpty {
                vector.withUnsafeBytes { data.append(contentsOf: $0) }
            }
            return (data, nonEmpty.count)
        }

        /// - Parameters:
        ///   - data: Concatenated Float32 bytes produced by `encode(_:)`.
        ///   - count: How many vectors `data` holds.
        static func decode(_ data: Data, count: Int) -> [[Float]] {
            let floatCount = data.count / MemoryLayout<Float>.stride
            guard count > 0, floatCount > 0, floatCount % count == 0 else { return [] }

            // Copy rather than rebind: Data's storage isn't guaranteed to be Float-aligned.
            var floats = [Float](repeating: 0, count: floatCount)
            _ = floats.withUnsafeMutableBytes { data.copyBytes(to: $0) }

            let dimension = floatCount / count
            return stride(from: 0, to: floatCount, by: dimension).map { Array(floats[$0..<($0 + dimension)]) }
        }
    }
}

extension ModelContainer {
    static var agentStoreURL: URL {
        .applicationSupportDirectory.appending(path: "agent.store")
    }

    /// - Parameters:
    ///   - inMemory: Keeps the store out of Application Support, for tests and previews.
    ///   - url: Where the store file lives on disk. Ignored when `inMemory` is true.
    /// - Returns: The agent container. An on-disk store that can't be opened (e.g. an
    ///   incompatible schema) is deleted and recreated, since everything in it can be rebuilt.
    static func makeAgentContainer(inMemory: Bool = false, url: URL = agentStoreURL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: AgentSchemaV1.self)
        let configuration = inMemory
            ? ModelConfiguration("Agent", schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration("Agent", schema: schema, url: url)
        let open = { try ModelContainer(for: schema, migrationPlan: AgentMigrationPlan.self, configurations: configuration) }

        do {
            return try open()
        } catch where !inMemory {
            LoggerService.main.error("Agent store unreadable, rebuilding: \(error)")
            try eraseAgentStore(at: url)
            return try open()
        }
    }

    /// - Parameter url: The store file. Its `-wal` and `-shm` companions are removed too.
    static func eraseAgentStore(at url: URL = agentStoreURL) throws {
        for suffix in ["", "-wal", "-shm"] {
            let file = URL(filePath: url.path(percentEncoded: false) + suffix)
            if FileManager.default.fileExists(atPath: file.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: file)
            }
        }
    }
}
