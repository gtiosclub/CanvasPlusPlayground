//
//  CanvasRepository.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import SwiftData
import SwiftUI

@MainActor
class CanvasRepository {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    init() {
        self.modelContainer = try! ModelContainer(
            for: Course.self,
            Announcement.self,
            Assignment.self,
            AssignmentGroup.self,
            Enrollment.self,
            File.self,
            Folder.self,
            Quiz.self,
            Module.self,
            ModuleItem.self,
            Submission.self,
            User.self,
            Profile.self,
            DiscussionTopic.self,
            Page.self
            // TODO: Add cacheable models here
        )
        self.modelContext = ModelContext(modelContainer)
        modelContext.autosaveEnabled = true
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

        return try modelContext.fetchCount(descriptor)
    }

    func delete(_ model: any PersistentModel) {
        modelContext.delete(model)
    }

    /// Push SwiftData changes to disk.
    func flush() {
        do {
            try modelContext.save()
        } catch {
            logger.error("Trouble saving to cache: \(error)")
        }
    }

    func merge<T>(other: T, into model: T) where T: Cacheable {
        model.merge(with: other)
    }

    func setAutosave(_ enabled: Bool) async {
        self.modelContext.autosaveEnabled = enabled
    }

}

enum CacheError: Error {
    case encodingError, decodingError
}
