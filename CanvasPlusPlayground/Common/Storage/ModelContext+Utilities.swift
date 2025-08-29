//
//  ModelContext+Utilities.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/8/25.
//

import Combine
import SwiftData
import SwiftUI

extension ModelContext {
    /// Don't use for writes! Only reads. `StorageHandler.main` is meant for main thread writes - to serialize operations.
    @MainActor
    static var shared: ModelContext {
        let modelContext = ModelContainer.shared.mainContext
        modelContext.autosaveEnabled = true
        return modelContext
    }
}

typealias SchemaLatest = CanvasSchemaV1

extension ModelContainer {
    static var shared: ModelContainer!

    static func setupSharedModelContainer(
        for schema: VersionedSchema.Type = SchemaLatest.self,
        inMemory: Bool = false
    ) throws {
        let schema = Schema(versionedSchema: schema)
        let modelConfig = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        let modelContainer = try ModelContainer(
            for: schema,
            migrationPlan: MigrationPlan.self,
            configurations: modelConfig
        )

        Self.shared = modelContainer
    }

    static func eraseSQLiteStore() throws {
        let appSupportDir = URL.applicationSupportDirectory.path(percentEncoded: false)
        let appSupportFiles = try FileManager.default.contentsOfDirectory(atPath: appSupportDir)

        for file in appSupportFiles {
            guard file.contains("default.store") else { continue }
            let fileURL = URL(fileURLWithPath: appSupportDir.appending(file))
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}

extension NotificationCenter {
    /// To listen to DB changes from main thread (for debugging)
    var managedObjectContextDidSavePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        publisher(for: .NSManagedObjectContextDidSave).receive(on: DispatchQueue.main)
    }
}
