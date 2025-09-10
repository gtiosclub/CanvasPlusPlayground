//
//  UserAPI.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/18/24.
//

import Foundation

// swiftlint:disable identifier_name
// https://github.com/instructure/canvas-ios/blob/49a3e347116d623638c66b7adbcc946294faa212/Core/Core/People/APIUser.swift
// https://canvas.instructure.com/doc/api/users.html
struct UserAPI: APIResponse, Identifiable {
    typealias Model = User

    let id: Int
    let name: String
    let sortable_name: String
    let last_name: String?
    let first_name: String?
    let short_name: String
    let sis_user_id: String?
    let sis_import_id: Int?
    let integration_id: String?
    let login_id: String?
    let avatar_url: URL?
    let avatar_state: String?
    let enrollments: [EnrollmentAPI]?
    let email: String?
    let locale: String?
    let last_login: String?
    let time_zone: String?
    let bio: String?
    let pronouns: String?
    var role: String?

    func createModel() -> User {
        User(from: self)
    }
}

// This struct is designed for lightweight user presentation in UI contexts as per the provided example. It is used by the submissions comment API
struct UserDisplay: Identifiable, Codable {
    let pronouns: String?
    let id: Int
    let anonymous_dd: String?
    let display_name: String?
    let avatar_image_url: URL?
    let html_url: URL?
}

// MARK: Preview
extension UserAPI {
    static let sample1 = UserAPI(
        id: 1001,
        name: "Alex Chen",
        sortable_name: "Chen, Alex",
        last_name: "Chen",
        first_name: "Alex",
        short_name: "Alex",
        sis_user_id: "AC1001",
        sis_import_id: 5001,
        integration_id: "INT-1001",
        login_id: "achen",
        avatar_url: URL(string: "https://canvas.example.edu/users/1001/avatar.png"),
        avatar_state: "approved",
        enrollments: nil,
        email: "alex.chen@example.edu",
        locale: "en",
        last_login: "2025-03-20T14:30:45Z",
        time_zone: "America/Los_Angeles",
        bio: "Computer Science major with an interest in mobile app development.",
        pronouns: "he/him",
        role: "student"
    )
    static let sample2 = UserAPI(
        id: 1002,
        name: "Jamie Smith",
        sortable_name: "Smith, Jamie",
        last_name: "Smith",
        first_name: "Jamie",
        short_name: "Jamie",
        sis_user_id: "JS1002",
        sis_import_id: 5002,
        integration_id: "INT-1002",
        login_id: "jsmith",
        avatar_url: URL(string: "https://canvas.example.edu/users/1002/avatar.png"),
        avatar_state: "approved",
        enrollments: nil,
        email: "jamie.smith@example.edu",
        locale: "en",
        last_login: "2025-03-23T09:15:22Z",
        time_zone: "America/Chicago",
        bio: "Design student focusing on UI/UX for mobile applications.",
        pronouns: "they/them",
        role: "student"
    )
}

/*
 // A Canvas user, e.g. a student, teacher, administrator, observer, etc.
 {
   // The ID of the user.
   "id": 2,
   // The name of the user.
   "name": "Sheldon Cooper",
   // The name of the user that is should be used for sorting groups of users, such
   // as in the gradebook.
   "sortable_name": "Cooper, Sheldon",
   // The last name of the user.
   "last_name": "Cooper",
   // The first name of the user.
   "first_name": "Sheldon",
   // A short name the user has selected, for use in conversations or other less
   // formal places through the site.
   "short_name": "Shelly",
   // The SIS ID associated with the user.  This field is only included if the user
   // came from a SIS import and has permissions to view SIS information.
   "sis_user_id": "SHEL93921",
   // The id of the SIS import.  This field is only included if the user came from
   // a SIS import and has permissions to manage SIS information.
   "sis_import_id": 18,
   // The integration_id associated with the user.  This field is only included if
   // the user came from a SIS import and has permissions to view SIS information.
   "integration_id": "ABC59802",
   // The unique login id for the user.  This is what the user uses to log in to
   // Canvas.
   "login_id": "sheldon@caltech.example.com",
   // If avatars are enabled, this field will be included and contain a url to
   // retrieve the user's avatar.
   "avatar_url": "https://en.gravatar.com/avatar/d8cb8c8cd40ddf0cd05241443a591868?s=80&r=g",
   // Optional: If avatars are enabled and caller is admin, this field can be
   // requested and will contain the current state of the user's avatar.
   "avatar_state": "approved",
   // Optional: This field can be requested with certain API calls, and will return
   // a list of the users active enrollments. See the List enrollments API for more
   // details about the format of these records.
   "enrollments": null,
   // Optional: This field can be requested with certain API calls, and will return
   // the users primary email address.
   "email": "sheldon@caltech.example.com",
   // Optional: This field can be requested with certain API calls, and will return
   // the users locale in RFC 5646 format.
   "locale": "tlh",
   // Optional: This field is only returned in certain API calls, and will return a
   // timestamp representing the last time the user logged in to canvas.
   "last_login": "2012-05-30T17:45:25Z",
   // Optional: This field is only returned in certain API calls, and will return
   // the IANA time zone name of the user's preferred timezone.
   "time_zone": "America/Denver",
   // Optional: The user's bio.
   "bio": "I like the Muppets.",
   // Optional: This field is only returned if pronouns are enabled, and will return
   // the pronouns of the user.
   "pronouns": "he/him"
 }
 */

