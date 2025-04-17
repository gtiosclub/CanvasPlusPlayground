//
//  ModelContext+Utilities.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/8/25.
//

import SwiftData
import SwiftUI
import Combine

extension ModelContext {
    /// Don't use for writes! Only reads. `StorageHandler.main` is meant for main thread writes - to serialize operations.
    @MainActor
    static var shared: ModelContext {
        let modelContext = ModelContainer.shared.mainContext
        modelContext.autosaveEnabled = true
        return modelContext
    }

    func existingModel<T: Cacheable>(forId id: String) -> T? {
        try? fetch(
            FetchDescriptor<T>(predicate: #Predicate { $0.id == id })
        ).first
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
}

extension NotificationCenter {
    /// To listen to DB changes from main thread (for debugging)
    var managedObjectContextDidSavePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .NSManagedObjectContextDidSave).receive(on: DispatchQueue.main)
    }
}
