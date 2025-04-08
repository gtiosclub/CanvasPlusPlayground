//
//  CanvasRepository.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import SwiftData

@MainActor
class CanvasRepository {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    init() {
        self.modelContext = ModelContext.shared
        self.modelContainer = modelContext.container
    }

    func insert<T>(_ item: T) where T: Cacheable {
        modelContext.insert(item)
    }

    /// Gets all data based on type. e.g. all Course objects to get all courses
    func get<T>(
        descriptor: FetchDescriptor<T>
    ) throws -> [T]? where T: Cacheable {
        let models: [T] = try modelContext.fetch(descriptor)

        // Make sure model exists.
        if !models.isEmpty {
            return models
        } else { return nil }
    }

    func count<T>(
        descriptor: FetchDescriptor<T>
    ) throws -> Int where T: Cacheable {
        try modelContext.fetchCount(descriptor)
    }

    func delete(_ model: any PersistentModel) {
        modelContext.delete(model)
    }

    /// Push SwiftData changes to disk.
    func flush() {
        do {
            try modelContext.save()
        } catch {
            LoggerService.main.error("Trouble saving to cache: \(error)")
        }
    }

    func merge<T>(other: T, into model: T) where T: Cacheable {
        model.merge(with: other)
    }

    func setAutosave(_ enabled: Bool) async {
        self.modelContext.autosaveEnabled = enabled
    }
}
