//
//  FolderAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

struct FolderAPI: APIResponse {
    typealias Model = Folder
    
    var id: Int
    var name: String?
    var full_name: String?
    var context_id: Int?
    var context_type: String?
    var parent_folder_id: Int?
    var created_at: String?
    var updated_at: String?
    var lock_at: String?
    var unlock_at: String?
    var position: Int?
    var locked: Bool?
    var folders_url: String?
    var files_url: String?
    var files_count: Int?
    var folders_count: Int?
    var hidden: Bool?
    var locked_for_user: Bool?
    var hidden_for_user: Bool?
    var for_submissions: Bool?
    var can_upload: Bool?
    
    func createModel() -> Folder {
        Folder(api: self)
    }
}
