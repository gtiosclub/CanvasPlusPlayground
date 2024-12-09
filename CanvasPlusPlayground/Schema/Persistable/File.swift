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
    var parentId: String
    
    var uuid: String?
    var folderId: Int?
    var displayName: String?
    var filename: String?
    var uploadStatus: String?
    var contentType: String?
    var url: String?
    var size: Int?
    var createdAt: String?
    var updatedAt: String?
    var unlockAt: String?
    var locked: Bool?
    var hidden: Bool?
    var lockAt: String?
    var hiddenForUser: Bool?
    var thumbnailUrl: String?
    var modifiedAt: String?
    var mimeClass: String?
    var mediaEntryID: String?
    var category: String?
    var lockedForUser: Bool?
    var visibilityLevel: String?

    // MARK: - Decodable
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(ServerID.self, forKey: .id)
        self.id =  String(describing: id)
        
        self.parentId = try container.decodeIfPresent(String.self, forKey: .parentId) ?? ""
        
        // Decode remaining properties
        self.uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
        self.folderId = try container.decodeIfPresent(Int.self, forKey: .folderID)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.filename = try container.decodeIfPresent(String.self, forKey: .filename)
        self.uploadStatus = try container.decodeIfPresent(String.self, forKey: .uploadStatus)
        self.contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.size = try container.decodeIfPresent(Int.self, forKey: .size)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        self.unlockAt = try container.decodeIfPresent(String.self, forKey: .unlockAt)
        self.locked = try container.decodeIfPresent(Bool.self, forKey: .locked)
        self.hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        self.lockAt = try container.decodeIfPresent(String.self, forKey: .lockAt)
        self.hiddenForUser = try container.decodeIfPresent(Bool.self, forKey: .hiddenForUser)
        self.thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        self.modifiedAt = try container.decodeIfPresent(String.self, forKey: .modifiedAt)
        self.mimeClass = try container.decodeIfPresent(String.self, forKey: .mimeClass)
        self.mediaEntryID = try container.decodeIfPresent(String.self, forKey: .mediaEntryID)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.lockedForUser = try container.decodeIfPresent(Bool.self, forKey: .lockedForUser)
        self.visibilityLevel = try container.decodeIfPresent(String.self, forKey: .visibilityLevel)
    }

    // MARK: - Encodable
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encodeIfPresent(parentId, forKey: .parentId)
        
        try container.encodeIfPresent(uuid, forKey: .uuid)
        try container.encodeIfPresent(folderId, forKey: .folderID)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(filename, forKey: .filename)
        try container.encodeIfPresent(uploadStatus, forKey: .uploadStatus)
        try container.encodeIfPresent(contentType, forKey: .contentType)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(unlockAt, forKey: .unlockAt)
        try container.encodeIfPresent(locked, forKey: .locked)
        try container.encodeIfPresent(hidden, forKey: .hidden)
        try container.encodeIfPresent(lockAt, forKey: .lockAt)
        try container.encodeIfPresent(hiddenForUser, forKey: .hiddenForUser)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encodeIfPresent(modifiedAt, forKey: .modifiedAt)
        try container.encodeIfPresent(mimeClass, forKey: .mimeClass)
        try container.encodeIfPresent(mediaEntryID, forKey: .mediaEntryID)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(lockedForUser, forKey: .lockedForUser)
        try container.encodeIfPresent(visibilityLevel, forKey: .visibilityLevel)
    }

    // MARK: - Merge
    func merge(with other: File) {
        self.uuid = other.uuid
        self.folderId = other.folderId
        self.displayName = other.displayName
        self.filename = other.filename
        self.uploadStatus = other.uploadStatus
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
        self.category = other.category
        self.lockedForUser = other.lockedForUser
        self.visibilityLevel = other.visibilityLevel
    }

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case parentId
        
        case uuid
        case folderID = "folder_id"
        case displayName = "display_name"
        case filename
        case uploadStatus = "upload_status"
        case contentType = "content-type"
        case url
        case size
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case unlockAt = "unlock_at"
        case locked
        case hidden
        case lockAt = "lock_at"
        case hiddenForUser = "hidden_for_user"
        case thumbnailUrl = "thumbnail_url"
        case modifiedAt = "modified_at"
        case mimeClass = "mime_class"
        case mediaEntryID = "media_entry_id"
        case category
        case lockedForUser = "locked_for_user"
        case visibilityLevel = "visibility_level"
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
