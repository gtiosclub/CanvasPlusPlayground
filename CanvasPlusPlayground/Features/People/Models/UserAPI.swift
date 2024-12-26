//
//  UserAPI.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/18/24.
//

import Foundation

struct UserAPI: APIResponse {
    typealias Model = NoOpCacheable
    
    let id: Int?
    let name: String?
    let sortable_name: String?
    let last_name: String?
    let first_name: String?
    let short_name: String?
    let sis_user_id: String?
    let sis_import_id: Int?
    let integration_id: String?
    let login_id: String?
    let avatar_url: URL?
    let avatar_state: String?
    let enrollments: [String]?
    let email: String?
    let locale: String?
    let last_login: String?
    let time_zone: String?
    let bio: String?
    let pronouns: String?
    var role: String?
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
   // Optional: This field is only returned if pronouns are enabled, and will
   // return the pronouns of the user.
   "pronouns": "he/him"
 }
 */
