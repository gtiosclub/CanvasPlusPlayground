//
//  StorageWriteHandler.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/5/25.
//

import SwiftData

@ModelActor
actor StorageWriteHandler {

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
