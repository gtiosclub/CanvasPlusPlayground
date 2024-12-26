//
//  AnnouncementAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

struct AnnouncementAPI: APIResponse {
    typealias Model = Announcement
    
    let id: Int
    var title: String?
    var created_at: Date?
    var message: String?
    
    func createModel() -> Announcement {
        Announcement(api: self)
    }
}
