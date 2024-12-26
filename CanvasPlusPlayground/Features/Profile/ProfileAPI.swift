//
//  ProfileAPI.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/18/24.
//

import Foundation

struct ProfileAPI: APIResponse {
    typealias Model = NoOpCacheable
    
    let id: Int?
    let name: String?
    let short_name: String?
    let sortable_name: String?
    let title: String?
    let bio: String?
    let pronunciation: String?
    let primary_email: String?
    let login_id: String?
    let sis_user_id: String?
    let lti_user_id: String?
    let avatar_url: URL?
    let calendar: CalendarLink?
    let time_zone: String?
    let locale: String?
    let k5_user: Bool?
    let use_classic_font_in_k5: Bool?

}
