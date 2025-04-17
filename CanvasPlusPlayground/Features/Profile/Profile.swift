//
//  Profile.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/13/24.
//

import Foundation
import SwiftData

typealias Profile = CanvasSchemaV1.Profile

extension CanvasSchemaV1 {
    @Model
    class Profile: Cacheable {
        typealias ID = String
        typealias ServerID = Int

        @Attribute(.unique)
        let id: String
        var name: String?
        var shortName: String?
        var sortableName: String?
        var title: String?
        var bio: String?
        var pronunciation: String?
        var primaryEmail: String?
        var loginId: String?
        var sisUserId: String?
        var ltiUserId: String?
        var avatarUrl: URL?
        var timeZone: String?
        var locale: String?
        var isK5User: Bool?
        var useClassicFontInK5: Bool?

        // MARK: Custom
        var tag: String

        init(from profileAPI: ProfileAPI) {
            self.id = String(profileAPI.id)
            self.name = profileAPI.name
            self.shortName = profileAPI.short_name
            self.sortableName = profileAPI.sortable_name
            self.title = profileAPI.title
            self.bio = profileAPI.bio
            self.pronunciation = profileAPI.pronunciation
            self.primaryEmail = profileAPI.primary_email
            self.loginId = profileAPI.login_id
            self.sisUserId = profileAPI.sis_user_id
            self.ltiUserId = profileAPI.lti_user_id
            self.avatarUrl = profileAPI.avatar_url
            self.timeZone = profileAPI.time_zone
            self.locale = profileAPI.locale
            self.isK5User = profileAPI.k5_user
            self.useClassicFontInK5 = profileAPI.use_classic_font_in_k5
            self.tag = ""
        }

        func merge(with other: Profile) {
            self.name = other.name
            self.shortName = other.shortName
            self.sortableName = other.sortableName
            self.title = other.title
            self.bio = other.bio
            self.pronunciation = other.pronunciation
            self.primaryEmail = other.primaryEmail
            self.loginId = other.loginId
            self.sisUserId = other.sisUserId
            self.ltiUserId = other.ltiUserId
            self.avatarUrl = other.avatarUrl
            self.timeZone = other.timeZone
            self.locale = other.locale
            self.isK5User = other.isK5User
            self.useClassicFontInK5 = other.useClassicFontInK5
        }
    }

}
