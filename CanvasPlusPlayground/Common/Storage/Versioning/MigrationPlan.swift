//
//  MigrationPlan.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/17/25.
//

import SwiftData

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CanvasSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }

    // MARK: Migration Stages
}
