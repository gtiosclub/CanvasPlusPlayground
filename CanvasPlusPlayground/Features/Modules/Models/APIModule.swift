//
//  APIModule.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import Foundation

// swiftlint:disable commented_code identifier_name
enum ModuleState: String, Codable {
    case locked, unlocked, started, completed
}

// https://canvas.instructure.com/doc/api/modules.html
struct APIModule: APIResponse {
    typealias Model = Module

    let id: Int
    /// The state of the module: `active` or `deleted`
    let workflow_state: WorkflowState?
    /// The position (order) of the module in this course.
    let position: Int
    let name: String
    /// The date this module will unlock.
    let unlock_at: Date?
    /// Whether the items of this module must be unlocked in order - item A of position 1 in this module
    /// must be completed before item B of position 2.
    let require_sequential_progress: Bool?
    /// IDs of modules that must be completed before this one is unlocked
    let prerequisite_module_ids: [Int]
    /// The number of items in the module
    let items_count: Int?
    /// The API URL to retrieve this module's items
    let items_url: URL?
    /// The contents (items) of this module. Only present if requested via `include[]=items` AND if module is not deemed too large by Canvas.
    let items: [APIModuleItem]?
    /// The state of this Module for the calling user one of 'locked', 'unlocked', 'started', 'completed'
    /// (Optional; present only if the caller is a student or if the optional parameter 'student_id' is included)
    let state: ModuleState?
    /// The date the user completed this module
    /// (Optional; present only if the caller is a student or if the optional parameter 'student_id' is included)
    let completed_at: Date?
    /// (Optional) Whether this module is published. This field is present only if the caller has permission to view unpublished modules.
    let published: Bool?
    // let publish_final_grade: Bool?

    func createModel() -> Model {
        Module(from: self)
    }

    enum WorkflowState: String, Codable {
        case active, deleted
    }
}
