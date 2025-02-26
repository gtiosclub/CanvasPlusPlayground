//
//  PagesAPI.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 2/21/25.
//

import Foundation

// swiftlint:disable commented_code
// swiftlint:disable identifier_name
// https://canvas.instructure.com/doc/api/pages.html
struct PageAPI: APIResponse, Identifiable {
    typealias Model = Page

    let page_id: Int
    let url: String
    let title: String?
    let created_at: Date?
    let updated_at: Date?
//    let editing_roles: String?
//    let last_edited_by: String?
    let body: String?
    let published: Bool
    let publish_at: Date?
    let front_page: Bool
//    let locked_for_user: Bool
//    let lock_info: String?
//    let lock_explanation: String?
//    let editor: String?
//    let block_editor_attributes: [String: Any]?

    var id: Int { page_id }

    func createModel() -> Page {
        Page(pageAPI: self)
    }
}
