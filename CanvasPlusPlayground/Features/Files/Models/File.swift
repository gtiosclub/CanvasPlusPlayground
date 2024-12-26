//
//  File.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

/*
 https://canvas.instructure.com/doc/api/files.html
 A file object looks like:
 {
   "id": 569,
   "uuid": "SUj23659sdfASF35h265kf352YTdnC4",
   "folder_id": 4207,
   "display_name": "file.txt",
   "filename": "file.txt",
   "content-type": "text/plain",
   "url": "http://www.example.com/files/569/download?download_frd=1&verifier=c6HdZmxOZa0Fiin2cbvZeI8I5ry7yqD7RChQzb6P",
   // file size in bytes
   "size": 43451,
   "created_at": "2012-07-06T14:58:50Z",
   "updated_at": "2012-07-06T14:58:50Z",
   "unlock_at": "2012-07-07T14:58:50Z",
   "locked": false,
   "hidden": false,
   "lock_at": "2012-07-20T14:58:50Z",
   "hidden_for_user": false,
   // Changes who can access the file. Valid options are 'inherit' (the default),
   // 'course', 'institution', and 'public'. Only valid in course endpoints.
   "visibility_level": "course",
   "thumbnail_url": null,
   "modified_at": "2012-07-06T14:58:50Z",
   // simplified content-type mapping
   "mime_class": "html",
   // identifier for file in third-party transcoding service
   "media_entry_id": "m-3z31gfpPf129dD3sSDF85SwSDFnwe",
   "locked_for_user": false,
   "lock_info": null,
   "lock_explanation": "This assignment is locked until September 1 at 12:00am",
   // optional: url to the document preview. This url is specific to the user
   // making the api call. Only included in submission endpoints.
   "preview_url": null
 }
 */

import Foundation
import SwiftData

@Model
class File: Cacheable {
    typealias ServerID = Int

    // MARK: - Attributes
    @Attribute(.unique) var id: String
    
    var uuid: String?
    var folderId: Int? // parent
    var displayName: String
    var filename: String
    var contentType: String?
    var url: String?
    var size: Int?
    var createdAt: Date?
    var updatedAt: Date?
    var unlockAt: Date?
    var locked: Bool?
    var hidden: Bool?
    var lockAt: Date?
    var hiddenForUser: Bool?
    var thumbnailUrl: String?
    var modifiedAt: Date?
    var mimeClass: String?
    var mediaEntryID: String?
    var lockedForUser: Bool?
    var visibilityLevel: String?

    init(api: FileAPI) {
        self.id = api.id.asString
        
        self.uuid = api.uuid
        self.folderId = api.folder_id
        self.displayName = api.display_name
        self.filename = api.filename
        self.contentType = api.content_type
        self.url = api.url
        self.size = api.size
        self.createdAt = api.created_at
        self.updatedAt = api.updated_at
        self.unlockAt = api.unlock_at
        self.locked = api.locked
        self.hidden = api.hidden
        self.hidden = api.hidden
        self.lockAt = api.lock_at
        self.hiddenForUser = api.hidden_for_user
        self.thumbnailUrl = api.thumbnail_url
        self.modifiedAt = api.modified_at
        self.mimeClass = api.mime_class
        self.mediaEntryID = api.media_entry_id
        self.lockedForUser = api.locked_for_user
        self.visibilityLevel = api.visibility_level
    }
    
    // MARK: - Merge
    func merge(with other: File) {
        self.uuid = other.uuid
        self.folderId = other.folderId
        self.displayName = other.displayName
        self.filename = other.filename
        self.contentType = other.contentType
        self.url = other.url
        self.size = other.size
        self.createdAt = other.createdAt
        self.updatedAt = other.updatedAt
        self.unlockAt = other.unlockAt
        self.locked = other.locked
        self.hidden = other.hidden
        self.lockAt = other.lockAt
        self.hiddenForUser = other.hiddenForUser
        self.thumbnailUrl = other.thumbnailUrl
        self.modifiedAt = other.modifiedAt
        self.mimeClass = other.mimeClass
        self.mediaEntryID = other.mediaEntryID
        self.lockedForUser = other.lockedForUser
        self.visibilityLevel = other.visibilityLevel
    }
}

fileprivate extension DateFormatter {
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
