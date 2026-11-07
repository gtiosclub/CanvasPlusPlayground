//
//  ChangeStoreEnvelope.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/31/26.
//

import Foundation

struct ChangeStoreEnvelope: Codable, Equatable, Sendable {
    static let currentFormatVersion = 1

    let formatVersion: Int
    let resetGeneration: UUID
    var commitRevision: UInt64
    var accounts: [AccountState]

    /// Creates a store envelope for a new or reconstructed state.
    /// - Parameter resetGeneration: Identity shared by mutations until the store resets.
    /// - Parameter commitRevision: Revision of the latest committed mutation.
    /// - Parameter accounts: Snapshots and unseen records grouped by account.
    init(
        resetGeneration: UUID = UUID(),
        commitRevision: UInt64 = 0,
        accounts: [AccountState] = []
    ) {
        self.formatVersion = Self.currentFormatVersion
        self.resetGeneration = resetGeneration
        self.commitRevision = commitRevision
        self.accounts = accounts
    }

    struct AccountState: Codable, Equatable, Sendable {
        let account: AccountKey
        var snapshots: [ChangeSnapshot] = []
        var records: [ChangeRecord] = []
        var baselines: [ChangeBaseline] = []
    }
}

extension ChangeStoreEnvelope.AccountState {
    /// Decodes account state written before or after baselines were introduced.
    /// - Parameters:
    ///   - decoder: Source of the persisted account state.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        account = try container.decode(AccountKey.self, forKey: .account)
        snapshots = try container.decode([ChangeSnapshot].self, forKey: .snapshots)
        records = try container.decode([ChangeRecord].self, forKey: .records)
        if container.contains(.baselines) {
            baselines = try container.decode([ChangeBaseline].self, forKey: .baselines)
        } else {
            baselines = []
        }
    }
}
