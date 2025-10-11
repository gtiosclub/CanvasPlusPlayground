//
//  RecentItemsManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI
import Combine

@Observable
class RecentItemsManager: ListWidgetDataSource {
    static let shared = RecentItemsManager()

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

    // ListWidgetDataSource
    var widgetData: [ListWidgetData] {
        get {
            recentItems.prefix(10).compactMap { item in
                guard let title = getTitle(for: item) else { return nil }
                return ListWidgetData(
                    id: item.uniqueKey,
                    title: title,
                    description: getDescription(for: item)
                )
            }
        }
        set { }
    }

    var fetchStatus: WidgetFetchStatus = .loading
    var refreshTrigger = PassthroughSubject<Void, Never>()

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

        refreshTrigger.send()
    }

    func clearAllRecentItems() {
        recentItems.removeAll()
        refreshTrigger.send()
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

    func loadRecentItemsData() async {
        await withTaskGroup(of: Void.self) { group in
            for item in recentItems {
                group.addTask {
                    try? await item.fetchData()
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func getTitle(for item: RecentItem) -> String? {
        guard let data = item.data else { return nil }

        switch data {
        case .announcement(let announcement):
            return announcement.title
        case .assignment(let assignment):
            return assignment.name
        case .file(let file):
            return file.displayName
        case .quiz(let quiz):
            return quiz.title
        }
    }

    private func getDescription(for item: RecentItem) -> String {
        guard let data = item.data else {
            return "Viewed \(item.viewedAt.formatted(.relative(presentation: .named)))"
        }

        switch data {
        case .announcement(let announcement):
            return announcement.message?
                .stripHTML()
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        case .assignment(let assignment):
            if let dueDate = assignment.dueDate {
                return "Due \(dueDate.formatted(.relative(presentation: .named)))"
            }
            return "Viewed \(item.viewedAt.formatted(.relative(presentation: .named)))"
        case .file:
            return "Viewed \(item.viewedAt.formatted(.relative(presentation: .named)))"
        case .quiz(let quiz):
            if let dueDate = quiz.dueDate {
                return "Due \(dueDate.formatted(.relative(presentation: .named)))"
            }
            return "Viewed \(item.viewedAt.formatted(.relative(presentation: .named)))"
        }
    }

    // MARK: - ListWidgetDataSource
    func fetchData(context: WidgetContext) async throws {
        fetchStatus = .loading
        getRecentItems()
        await loadRecentItemsData()
        fetchStatus = .loaded
    }

    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        guard let item = recentItems.first(where: { $0.uniqueKey == data.id }),
              let destination = item.navigationDestination else {
            return .recentItems
        }
        return destination
    }
}
