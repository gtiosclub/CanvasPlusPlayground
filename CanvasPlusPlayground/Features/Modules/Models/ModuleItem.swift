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
    var moduleID: Int
    var position: Int
    var title: String
    var indent: Int
    var type: ModuleItemType
    var htmlURL: URL?
    var url: URL?
    var completionRequirement: CompletionRequirement?
    var contentDetails: APIModuleItem.ContentDetails?
    var published: Bool?
    var quizLti: Bool?

    // MARK: Custom
    var courseID: String?

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
