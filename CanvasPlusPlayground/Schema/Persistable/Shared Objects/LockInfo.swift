//
//  LockInfo.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation

struct LockInfo: Codable {
    let assetString: String
    let unlockAt: Date?
    let lockAt: Date?
    //let contextModule: String?
    let manuallyLocked: Bool
    
    enum CodingKeys: String, CodingKey {
        case assetString = "asset_string"
        case unlockAt = "unlock_at"
        case lockAt = "lock_at"
        case manuallyLocked = "manually_locked"
    }
}
