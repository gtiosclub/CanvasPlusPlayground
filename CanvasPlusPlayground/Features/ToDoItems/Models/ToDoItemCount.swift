//
//  ToDoItemCount.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/29/25.
//

import Foundation
import SwiftData

typealias ToDoItemCount = CanvasSchemaV1.ToDoItemCount

extension CanvasSchemaV1 {
    @Model
    class ToDoItemCount {
        typealias ID = String

        @Attribute(.unique)
        let id: String
        var parentID: String

        var needsGradingCount: Int
        var assignmentsNeedingSubmitting: Int

        init(from model: ToDoItemCountAPI) {
            self.id = UUID().uuidString // not included with API
            self.parentID = ""
            self.needsGradingCount = model.needsGradingCount
            self.assignmentsNeedingSubmitting = model.assignmentsNeedingSubmitting
        }

        enum CodingKeys: String, CodingKey {
            case needsGradingCount = "needs_grading_count"
            case assignmentsNeedingSubmitting = "assignments_needing_submitting"
        }
    }
}

extension ToDoItemCount: Cacheable {
    func merge(with other: ToDoItemCount) {
        self.needsGradingCount = other.needsGradingCount
        self.assignmentsNeedingSubmitting = other.assignmentsNeedingSubmitting
    }
}
