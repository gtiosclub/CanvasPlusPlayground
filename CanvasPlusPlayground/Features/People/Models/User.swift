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

    var enrollmentRoles: [EnrollmentType] {
        Array(
            Set(
                enrollments?.compactMap { EnrollmentType(rawValue: $0.type) } ?? []
            )
        )
        .sorted { $0.rawValue < $1.rawValue }
    }
    var enrollments: [EnrollmentAPI]?

    // MARK: Custom
    var courseId: String?
    var tag: String
    var avatarImageData: Data?

    init(from userAPI: UserAPI) {
        self.id = String(userAPI.id)
        self.name = userAPI.name
        self.shortName = userAPI.short_name
        self.sortableName = userAPI.sortable_name
        self.avatarURL = userAPI.avatar_url
        self.email = userAPI.email
        self.pronouns = userAPI.pronouns
        self.role = userAPI.role
        self.enrollments = userAPI.enrollments
        self.tag = ""
    }

    func merge(with other: User) {
        self.name = other.name
        self.sortableName = other.sortableName
        self.shortName = other.shortName
        self.avatarURL = other.avatarURL ?? self.avatarURL
        self.email = other.email ?? self.email
        self.pronouns = other.pronouns ?? self.pronouns
        self.role = other.role ?? self.role

        self.enrollments = other.enrollments ?? self.enrollments
    }

    var hasAvatar: Bool {
        guard let avatarURL else { return false }

        return !avatarURL.absoluteString.hasSuffix("avatar-50.png")
    }
}

enum EnrollmentType: String, Codable, CaseIterable {
    case teacher = "TeacherEnrollment", student = "StudentEnrollment", taEnrollment = "TaEnrollment",
         observer = "ObserverEnrollment", designer = "DesignerEnrollment"

    var displayName: String {
        switch self {
        case .teacher:
            "Teacher"
        case .student:
            "Student"
        case .taEnrollment:
            "TA"
        case .observer:
            "Observer"
        case .designer:
            "Designer"
        }
    }

    var asFilter: String {
        switch self {
        case .teacher:
            "teacher"
        case .student:
            "student"
        case .taEnrollment:
            "ta"
        case .observer:
            "observer"
        case .designer:
            "designer"
        }
    }
}
