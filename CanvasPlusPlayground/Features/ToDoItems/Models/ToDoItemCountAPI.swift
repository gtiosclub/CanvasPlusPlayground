//
//  ToDoItemCount.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/29/25.
//

import Foundation

struct ToDoItemCountAPI: APIResponse {
    typealias Model = ToDoItemCount

    let needsGradingCount: Int
    let assignmentsNeedingSubmitting: Int

    enum CodingKeys: String, CodingKey {
        case needsGradingCount = "needs_grading_count"
        case assignmentsNeedingSubmitting = "assignments_needing_submitting"
    }

    func createModel() -> ToDoItemCount {
        ToDoItemCount(from: self)
    }
}
