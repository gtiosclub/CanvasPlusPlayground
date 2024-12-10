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

@Model
class Folder: Cacheable {
    typealias ServerID = Int
    
    @Attribute(.unique) var id: String
    var parentId: String
    
    var name: String?
    var fullName: String?
    var contextId: Int?
    var contextType: String?
    var parentFolderId: Int?
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
    
    required init(from decoder: any Decoder)  throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(ServerID.self, forKey: .id)
        self.id =  String(describing: id)
        
        self.parentId = try container.decodeIfPresent(String.self, forKey: .parentId) ?? ""
        
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        self.contextId = try container.decodeIfPresent(Int.self, forKey: .contextId)
        self.contextType = try container.decodeIfPresent(String.self, forKey: .contextType)
        self.parentFolderId = try container.decodeIfPresent(Int.self, forKey: .parentFolderId)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        self.lockAt = try container.decodeIfPresent(String.self, forKey: .lockAt)
        self.unlockAt = try container.decodeIfPresent(String.self, forKey: .unlockAt)
        self.position = try container.decodeIfPresent(Int.self, forKey: .position)
        self.locked = try container.decodeIfPresent(Bool.self, forKey: .locked)
        self.foldersUrl = try container.decodeIfPresent(String.self, forKey: .foldersUrl)
        self.filesUrl = try container.decodeIfPresent(String.self, forKey: .filesUrl)
        self.filesCount = try container.decodeIfPresent(Int.self, forKey: .filesCount)
        self.foldersCount = try container.decodeIfPresent(Int.self, forKey: .foldersCount)
        self.hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        self.lockedForUser = try container.decodeIfPresent(Bool.self, forKey: .lockedForUser)
        self.hiddenForUser = try container.decodeIfPresent(Bool.self, forKey: .hiddenForUser)
        self.forSubmissions = try container.decodeIfPresent(Bool.self, forKey: .forSubmissions)
        self.canUpload = try container.decodeIfPresent(Bool.self, forKey: .canUpload)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encodeIfPresent(parentId, forKey: .parentId)
        
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(fullName, forKey: .fullName)
        try container.encodeIfPresent(contextId, forKey: .contextId)
        try container.encodeIfPresent(contextType, forKey: .contextType)
        try container.encodeIfPresent(parentFolderId, forKey: .parentFolderId)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(lockAt, forKey: .lockAt)
        try container.encodeIfPresent(unlockAt, forKey: .unlockAt)
        try container.encodeIfPresent(position, forKey: .position)
        try container.encodeIfPresent(locked, forKey: .locked)
        try container.encodeIfPresent(foldersUrl, forKey: .foldersUrl)
        try container.encodeIfPresent(filesUrl, forKey: .filesUrl)
        try container.encodeIfPresent(filesCount, forKey: .filesCount)
        try container.encodeIfPresent(foldersCount, forKey: .foldersCount)
        try container.encodeIfPresent(hidden, forKey: .hidden)
        try container.encodeIfPresent(lockedForUser, forKey: .lockedForUser)
        try container.encodeIfPresent(hiddenForUser, forKey: .hiddenForUser)
        try container.encodeIfPresent(forSubmissions, forKey: .forSubmissions)
        try container.encodeIfPresent(canUpload, forKey: .canUpload)
    }
    
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
                
        case name
        case fullName = "full_name"
        case contextId = "context_id"
        case contextType = "context_type"
        case parentFolderId = "parent_folder_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lockAt = "lock_at"
        case unlockAt = "unlock_at"
        case position
        case locked
        case foldersUrl = "folders_url"
        case filesUrl = "files_url"
        case filesCount = "files_count"
        case foldersCount = "folders_count"
        case hidden
        case lockedForUser = "locked_for_user"
        case hiddenForUser = "hidden_for_user"
        case forSubmissions = "for_submissions"
        case canUpload = "can_upload"
    }
    
    
}
