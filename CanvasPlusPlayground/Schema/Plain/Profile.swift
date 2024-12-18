//
//  Profile.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/18/24.
//

import Foundation

struct Profile: Codable {
    let id: Int?
    let name: String?
    let shortName: String?
    let sortableName: String?
    let title: String?
    let bio: String?
    let pronunciation: String?
    let primaryEmail: String?
    let loginID: String?
    let sisUserID: String?
    let ltiUserID: String?
    let avatarURL: URL?
    let calendar: CalendarLink?
    let timeZone: String?
    let locale: String?
    let k5User: Bool?
    let useClassicFontInK5: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
        case sortableName = "sortable_name"
        case title
        case bio
        case pronunciation
        case primaryEmail = "primary_email"
        case loginID = "login_id"
        case sisUserID = "sis_user_id"
        case ltiUserID = "lti_user_id"
        case avatarURL = "avatar_url"
        case calendar
        case timeZone = "time_zone"
        case locale
        case k5User = "k5_user"
        case useClassicFontInK5 = "use_classic_font_in_k5"
    }
}
