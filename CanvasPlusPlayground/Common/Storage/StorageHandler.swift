//
//  StorageHandler.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/5/25.
//

import SwiftData
import SwiftUI

@ModelActor
actor StorageHandler {

    /// Must use this for all modifications to main-thread-bound models or reads. (e.g. even simple changes like MyModel.prop = false)
    @MainActor
    static var main = {
        StorageHandler(modelContainer: .shared) // TODO: enable autosave
    }()

    func save() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    func transaction<T>(_ block: (ModelContext) throws -> T) throws -> T {
        do {
            let result = try block(modelContext)
            try save()
            return result
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
