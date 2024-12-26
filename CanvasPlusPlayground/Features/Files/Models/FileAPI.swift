//
//  FileAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

//https://github.com/instructure/canvas-ios/blob/49a3e347116d623638c66b7adbcc946294faa212/Core/Core/Files/Model/API/APIFile.swift#L175
struct FileAPI: APIResponse {
    typealias Model = File
    
    let id: Int
    let uuid: String
    let folder_id: Int
    let display_name: String
    let filename: String
    let contentType: String
    var url: String?
    //var url: APIURL?
    // file size in bytes
    let size: Int?
    let created_at: Date
    let updated_at: Date
    let unlock_at: Date?
    let locked: Bool
    var hidden: Bool
    let lock_at: Date?
    let hidden_for_user: Bool
//    var thumbnail_url: APIURL?
    var thumbnail_url: String?
    let modified_at: Date
    // simplified content-type mapping
    let mime_class: String
    // identifier for file in third-party transcoding service
    let media_entry_id: String?
    let locked_for_user: Bool
    // let lock_info: [String: Any]?
    let lock_explanation: String?
    // optional: url to the document preview. This url is specific to the user
    // making the api call. Only included in submission endpoints.
//    var preview_url: APIURL?
    var preview_url: String?
    let avatar: APIFileToken?
    var usage_rights: APIUsageRights?
    let visibility_level: String?
    
    func createModel() -> File {
        File(api: self)
    }
}

struct APIFileToken: Codable, Equatable {
    let token: String
}

struct APIUsageRights: Codable, Equatable {
    let legal_copyright: String?
    let license: String?
    let use_justification: UseJustification?
}

enum UseJustification: String, Codable, CaseIterable {
    case own_copyright, used_by_permission, public_domain, fair_use, creative_commons

    var label: String {
        switch self {
        case .own_copyright:
            "I hold the copyright"
        case .used_by_permission:
            "I obtained permission"
        case .public_domain:
            "It is in the public domain"
        case .fair_use:
            "It is a fair use or similar exception"
        case .creative_commons:
            "It is licensed under Creative Commons"
        }
    }
}
