//
//  Module.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import Foundation
import SwiftData

@Model
class Module: Cacheable {
    typealias ServerID = Int

    var id: String
    /// The state of the module: `active` or `deleted`
    var workflowState: APIModule.WorkflowState?
    /// The position (order) of the module in this course.
    var position: Int
    var name: String
    /// The date this module will unlock.
    var unlockAt: Date?
    /// Whether the items of this module must be unlocked in order - item A of position 1 in this module must be completed before item B of position 2.
    var requiresSequentialProgress: Bool
    /// IDs of modules that must be completed before this one is unlocked
    var prerequisiteModuleIds: [Int]
    /// The number of items in the module
    var itemsCount: Int
    /// The contents (items) of this module. Only present if requested via `include[]=items` AND if module is not deemed too large by Canvas.
    var items: [APIModuleItem]?
    /// The state of this Module for the calling user one of 'locked', 'unlocked', 'started', 'completed' (Optional; present only if the caller is a student or if the optional parameter 'student_id' is included)
    var state: ModuleState?
    /// The date the user completed this module (Optional; present only if the caller is a student or if the optional parameter 'student_id' is included)
    var completedAt: Date?
    /// (Optional) Whether this module is published. This field is present only if the caller has permission to view unpublished modules.
    var published: Bool?

    // MARK: Custom
    var courseID: String?

    init(from moduleApi: APIModule) {
        self.id = String(moduleApi.id)
        self.workflowState = moduleApi.workflow_state
        self.position = moduleApi.position
        self.name = moduleApi.name
        self.unlockAt = moduleApi.unlock_at
        self.requiresSequentialProgress = moduleApi.require_sequential_progress ?? false
        self.prerequisiteModuleIds = moduleApi.prerequisite_module_ids
        self.itemsCount = moduleApi.items_count ?? 0
        self.items = moduleApi.items
        self.state = moduleApi.state
        self.completedAt = moduleApi.completed_at
        self.published = moduleApi.published
    }

    func merge(with other: Module) {
        self.workflowState = workflowState ?? self.workflowState
        self.position = other.position
        self.name = other.name
        self.unlockAt = other.unlockAt ?? self.unlockAt
        self.requiresSequentialProgress = other.requiresSequentialProgress
        self.prerequisiteModuleIds = other.prerequisiteModuleIds
        self.itemsCount = other.itemsCount
        self.items = other.items ?? self.items
        self.state = other.state ?? self.state
        self.completedAt = other.completedAt ?? self.completedAt
        self.published = other.published ?? self.published
    }
}
