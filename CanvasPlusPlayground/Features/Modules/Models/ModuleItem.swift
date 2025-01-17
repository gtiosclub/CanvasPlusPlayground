//
//  ModuleItem.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import Foundation
import SwiftData

@Model
class ModuleItem: Cacheable {
    typealias ServerID = Int

    var id: String
    /// The id of the module this item appears in
    var moduleID: Int
    /// The position (order) of the item in its module
    var position: Int
    var title: String
    /// 0-based indent level; used to show hierarchy
    var indent: Int
    /// The module type along with properties concerning that type, for one of
    /// 'File', 'Page', 'Discussion', 'Assignment', 'Quiz', 'SubHeader', 'ExternalUrl', 'ExternalTool'
    var type: ModuleItemType
    /// User-interactable link to the item in Canvas. (e.g. https://canvas.example.edu/courses/222/modules/items/768)
    var htmlURL: URL?
    /// Link to Canvas API Object, if applicable (e.g. https://canvas.example.edu/api/v1/courses/222/assignments/987)
    var url: URL?
    /// Criteria for this module item to be marked complete
    var completionRequirement: CompletionRequirement?
    /// (Present only if requested through `include[]=content_details`) If applicable, returns additional details specific to the associated object
    var contentDetails: APIModuleItem.ContentDetails?
    /// Whether this module item is published. This field is present only if the caller has permission to view unpublished items.
    var published: Bool?
    /// Whether the quiz (if applicable) is delivered  through an external LTI tool. It might be proctored, etc.
    var quizLti: Bool?

    // MARK: Custom
    var parentId: String?

    init(from itemAPI: APIModuleItem) {
        self.id = String(itemAPI.id)
        self.moduleID = itemAPI.module_id
        self.position = itemAPI.position
        self.title = itemAPI.title
        self.indent = itemAPI.indent ?? 0
        self.type = ModuleItemType(from: itemAPI)
        self.htmlURL = itemAPI.html_url
        self.url = itemAPI.url
        self.completionRequirement = itemAPI.completion_requirement
        self.contentDetails = itemAPI.content_details
        self.published = itemAPI.published
        self.quizLti = itemAPI.quiz_lti
    }

    func merge(with other: ModuleItem) {
        self.moduleID = other.moduleID
        self.position = other.position
        self.title = other.title
        self.indent = other.indent
        self.type = other.type
        self.htmlURL = other.htmlURL ?? self.htmlURL
        self.url = other.url ?? self.url
        self.completionRequirement = other.completionRequirement ?? self.completionRequirement
        self.contentDetails = other.contentDetails ?? self.contentDetails
        self.published = other.published ?? self.published
        self.quizLti = other.quizLti ?? self.quizLti
    }
}

enum ModuleItemType: Equatable, Codable {
    case file(id: String?)
    case discussion(id: String?)
    case assignment(id: String?)
    case quiz(id: String?)
    case externalURL(url: URL?)
    case externalTool(id: String?, url: URL?, newTab: Bool)
    case page(id: String?)
    case subHeader

    init(from moduleItemAPI: APIModuleItem) {
        let contentId = moduleItemAPI.content_id?.asString
        switch moduleItemAPI.type {
        case .file:
            self = .file(id: contentId)
        case .discussion:
            self = .discussion(id: contentId)
        case .assignment:
            self = .assignment(id: contentId)
        case .quiz:
            self = .quiz(id: contentId)
        case .externalURL:
            self = .externalURL(url: moduleItemAPI.external_url)
        case .externalTool:
            self = .externalTool(
                id: contentId,
                url: moduleItemAPI.external_url,
                newTab: moduleItemAPI.new_tab ?? false
            )
        case .page:
            self = .page(id: moduleItemAPI.page_url)
        case .subHeader:
            self = .subHeader
        }
    }
}
