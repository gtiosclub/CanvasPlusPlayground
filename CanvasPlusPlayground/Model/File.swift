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
struct File: Codable {
    let id: Int
    let uuid: String
    let folderID: Int
    let displayName: String
    let filename: String
    let uploadStatus: String
    let contentType: String
    let url: String
    let size: Int
    let createdAt: String
    let updatedAt: String
    let unlockAt: String?
    let locked: Bool
    let hidden: Bool
    let lockAt: String?
    let hiddenForUser: Bool
    let thumbnailUrl: String?
    let modifiedAt: String
    let mimeClass: String
    let mediaEntryID: String?
    let category: String
    let lockedForUser: Bool
    let visibilityLevel: String
    
    enum CodingKeys: String, CodingKey {
        case id
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
