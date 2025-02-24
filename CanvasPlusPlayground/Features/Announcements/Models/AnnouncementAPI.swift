//
//  AnnouncementAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

// swiftlint:disable identifier_name
// https://canvas.instructure.com/doc/api/announcements.html
struct AnnouncementAPI: APIResponse, Identifiable {
    typealias Model = Announcement

    let id: Int
    var title: String?
    var created_at: Date?
    var message: String?
    var context_code: String?

    func createModel() -> Announcement {
        Announcement(api: self)
    }
}
