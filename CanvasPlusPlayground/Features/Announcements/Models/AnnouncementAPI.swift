//
//  AnnouncementAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

// https://canvas.instructure.com/doc/api/announcements.html
struct AnnouncementAPI: APIResponse {
    typealias Model = Announcement

    // swiftlint:disable identifier_name
    let id: Int
    var title: String?
    var created_at: Date?
    var message: String?
    // swiftlint:enable identifier_name

    func createModel() -> Announcement {
        Announcement(api: self)
    }
}
