//
//  User.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/20/25.
//

import Foundation
import SwiftData

@Model
class User: Cacheable {
    typealias ID = String
    typealias ServerID = Int

    @Attribute(.unique)
    var id: String
    var name: String
    var sortableName: String
    var shortName: String
    var avatarURL: URL?
    var email: String?
    var pronouns: String?
    var role: String?

    var enrollmentRoles: [String] {
        Array(Set(enrollments.compactMap{ $0.role.replacingOccurrences(of: "Enrollment", with: "") })).sorted()
    }
    var enrollments: [EnrollmentAPI]

    // MARK: Custom
    var courseId: String?

    init(from userAPI: UserAPI) {
        self.id = String(userAPI.id)
        self.name = userAPI.name
        self.shortName = userAPI.short_name
        self.sortableName = userAPI.sortable_name
        self.avatarURL = userAPI.avatar_url
        self.email = userAPI.email
        self.pronouns = userAPI.pronouns
        self.role = userAPI.role
        self.enrollments = userAPI.enrollments ?? []
    }

    func merge(with other: User) {
        self.name = other.name
        self.sortableName = other.sortableName
        self.shortName = other.shortName
        self.avatarURL = other.avatarURL
        self.email = other.email
        self.pronouns = other.pronouns
        self.role = other.role
        self.enrollments = other.enrollments
    }

}
