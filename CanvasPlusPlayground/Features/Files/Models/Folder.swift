//
//  Folder.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/17/24.
//

import Foundation
import SwiftData

/*
 {
    "id": 4894139,
    "name": "Section X Worksheets",
    "full_name": "course files/Section X Worksheets",
    "context_id": 403196,
    "context_type": "Course",
    "parent_folder_id": 4477745,
    "created_at": "2024-08-20T16:53:36Z",
    "updated_at": "2024-08-20T16:53:36Z",
    "lock_at": null,
    "unlock_at": null,
    "position": 6,
    "locked": false,
    "folders_url": "https://gatech.instructure.com/api/v1/folders/4894139/folders",
    "files_url": "https://gatech.instructure.com/api/v1/folders/4894139/files",
    "files_count": 10,
    "folders_count": 0,
    "hidden": null,
    "locked_for_user": false,
    "hidden_for_user": false,
    "for_submissions": false,
    "can_upload": false
  }
 */

typealias Folder = CanvasSchemaV1.Folder

extension CanvasSchemaV1 {
    @Model
    class Folder {
        typealias ServerID = Int

        @Attribute(.unique) var id: String

        var name: String?
        var fullName: String?
        var contextId: Int?
        var contextType: String?
        var parentFolderId: Int? // folder
        var createdAt: String?
        var updatedAt: String?
        var lockAt: String?
        var unlockAt: String?
        var position: Int?
        var locked: Bool?
        var foldersUrl: String?
        var filesUrl: String?
        var filesCount: Int?
        var foldersCount: Int?
        var hidden: Bool?
        var lockedForUser: Bool?
        var hiddenForUser: Bool?
        var forSubmissions: Bool?
        var canUpload: Bool?

        // MARK: Custom
        var tag: String?

        init(api: FolderAPI) {
            self.id = api.id.asString
            self.name = api.name
            self.fullName = api.full_name
            self.contextId = api.context_id
            self.contextType = api.context_type
            self.parentFolderId = api.parent_folder_id
            self.createdAt = api.created_at
            self.updatedAt = api.updated_at
            self.lockAt = api.lock_at
            self.unlockAt = api.unlock_at
            self.position = api.position
            self.locked = api.locked
            self.foldersUrl = api.folders_url
            self.filesUrl = api.files_url
            self.filesCount = api.files_count
            self.foldersCount = api.folders_count
            self.hidden = api.hidden
            self.lockedForUser = api.locked_for_user
            self.hiddenForUser = api.hidden_for_user
            self.forSubmissions = api.for_submissions
            self.canUpload = api.can_upload
        }
    }
}

extension Folder: Cacheable {
    func merge(with other: Folder) {
        self.name = other.name
        self.fullName = other.fullName
        self.contextId = other.contextId
        self.contextType = other.contextType
        self.parentFolderId = other.parentFolderId
        self.createdAt = other.createdAt
        self.updatedAt = other.updatedAt
        self.lockAt = other.lockAt
        self.unlockAt = other.unlockAt
        self.position = other.position
        self.locked = other.locked
        self.foldersUrl = other.foldersUrl
        self.filesUrl = other.filesUrl
        self.filesCount = other.filesCount
        self.foldersCount = other.foldersCount
        self.hidden = other.hidden
        self.lockedForUser = other.lockedForUser
        self.hiddenForUser = other.hiddenForUser
        self.forSubmissions = other.forSubmissions
        self.canUpload = other.canUpload
    }
}
