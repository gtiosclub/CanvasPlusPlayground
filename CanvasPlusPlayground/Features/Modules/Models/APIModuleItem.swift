//
//  APIModuleItem.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import Foundation

// swiftlint:disable identifier_name
struct APIModuleItem: APIResponse, Identifiable {
    typealias Model = ModuleItem

    let id: Int
    /// The id of the module this item appears in
    let module_id: Int
    /// The position (order) of the item in its module
    let position: Int
    let title: String
    /// 0-based indent level; used to show hierarchy
    let indent: Int?
    /// The module type, one of 'File', 'Page', 'Discussion', 'Assignment', 'Quiz', 'SubHeader', 'ExternalUrl', 'ExternalTool'
    let type: APIModuleItemType
    /// The id of the object associated with the `type` of this item. (e.g. quiz id if `type` is Quiz)
    let content_id: Int?
    /// User-interactable link to the item in Canvas. (e.g. https://canvas.example.edu/courses/222/modules/items/768)
    let html_url: URL?
    /// Link to Canvas API Object, if applicable (e.g. https://canvas.example.edu/api/v1/courses/222/assignments/987)
    let url: URL?
    /// (Only if `type` is Page) Just an identifier for this page. Not actually a url. Url including this Id is the `url` property.
    let page_url: String?
    /// Only for `ExternalUrl` and `ExternalTool` types, the external url embedded or being pointed to.
    let external_url: URL?
    /// Only for `ExternalTool` type, whether the tool opens in a new tab.
    let new_tab: Bool?
    /// Criteria for this module item to be marked complete
    let completion_requirement: CompletionRequirement?
    /// (Present only if requested through `include[]=content_details`) If applicable, returns additional details specific to the associated object
    let content_details: ContentDetails?
    /// Whether this module item is published. This field is present only if the caller has permission to view unpublished items.
    let published: Bool?
    /// Whether the quiz (if applicable) is delivered  through an external LTI tool. It might be proctored, etc.
    let quiz_lti: Bool?

    func createModel() -> Model {
        ModuleItem(from: self)
    }

    struct ContentDetails: Codable {
        let points_possible: Double?
        let due_at: Date?
        let unlock_at: Date?
        let lock_at: Date?
        let locked_for_user: Bool?
        let lock_explanation: String?
    }
}

enum APIModuleItemType: String, Codable {
    case file = "File"
    case page = "Page"
    case discussion = "Discussion"
    case assignment = "Assignment"
    case quiz = "Quiz"
    case subHeader = "SubHeader"
    case externalURL = "ExternalUrl"
    case externalTool = "ExternalTool"
}

struct CompletionRequirement: Codable {
    let type: CompletionRequirementType
    let min_score: Double?
    let completed: Bool?
}

enum CompletionRequirementType: String, Codable {
    case min_score, must_view, must_submit, must_contribute, must_mark_done
}
