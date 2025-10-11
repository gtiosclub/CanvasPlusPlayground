//
//  RecentItemsManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI

@Observable
class RecentItemsManager {
    static let recentItemsKey = "recentItems"
    static let maxRecentItemsKey = "maxRecentItems"
    static let defaultMaxRecentItems = 50
    static let maxRecentItemsOptions = [25, 50, 75, 100]

    private(set) var recentItems: [RecentItem] = [] {
        didSet { saveRecentItems() }
    }

    var maxRecentItems: Int {
        didSet {
            UserDefaults.standard.set(maxRecentItems, forKey: Self.maxRecentItemsKey)
            trimRecentItemsIfNeeded()
        }
    }

    var recentItemsByType: [RecentItemType: [RecentItem]] {
        Dictionary(grouping: recentItems) { $0.type }
    }

    init() {
        let savedMax = UserDefaults.standard.integer(forKey: Self.maxRecentItemsKey)
        self.maxRecentItems = savedMax > 0 ? savedMax : Self.defaultMaxRecentItems
        getRecentItems()
    }

    func logRecentItem(
        itemID: String,
        courseID: String,
        type: RecentItemType
    ) {
        if let existingIndex = recentItems.firstIndex(where: {
            $0.id == itemID && $0.courseID == courseID && $0.type == type
        }) {
            let existingItem = recentItems.remove(at: existingIndex)
            recentItems.insert(existingItem, at: 0)
        } else {
            let newItem = RecentItem(
                id: itemID,
                courseID: courseID,
                type: type,
                viewedAt: Date()
            )
            recentItems.insert(newItem, at: 0)
            trimRecentItemsIfNeeded()
        }
    }

    func clearAllRecentItems() {
        recentItems.removeAll()
    }

    private func trimRecentItemsIfNeeded() {
        if recentItems.count > maxRecentItems {
            recentItems = Array(recentItems.prefix(maxRecentItems))
        }
    }

    private func saveRecentItems() {
        if let data = try? JSONEncoder().encode(recentItems) {
            UserDefaults.standard.set(data, forKey: Self.recentItemsKey)
        }
    }

    private func getRecentItems() {
        var result: [RecentItem] = []

        if let data = UserDefaults.standard.data(forKey: Self.recentItemsKey) {
            result = (try? JSONDecoder().decode([RecentItem].self, from: data)) ?? []
        }

        recentItems = Array(result.prefix(maxRecentItems))
    }
}
