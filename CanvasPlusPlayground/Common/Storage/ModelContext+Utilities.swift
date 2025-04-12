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
    static var shared: ModelContext = {
        let modelContext = ModelContainer.shared.mainContext
        modelContext.autosaveEnabled = true
        return modelContext
    }()

    func existingModel<T: Cacheable>(forId id: String) -> T? {
        try? fetch(
            FetchDescriptor<T>(predicate: #Predicate { $0.id == id })
        ).first
    }
}

extension ModelContainer {
    static var shared: ModelContainer = {
        // TODO: show data corruption message with prompt to reset local storage if this fails.
        let modelContainer = try! ModelContainer(
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
            Page.self,
            CanvasGroup.self,
            GroupMembership.self,
            CanvasTab.self
            // TODO: Add cacheable models here
        )

        return modelContainer
    }()
}

extension NotificationCenter {
    /// To listen to DB changes from main thread (for debugging)
    var managedObjectContextDidSavePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .NSManagedObjectContextDidSave).receive(on: DispatchQueue.main)
    }
}
