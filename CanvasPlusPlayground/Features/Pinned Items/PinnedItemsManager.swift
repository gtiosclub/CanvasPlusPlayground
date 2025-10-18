//
//  PinnedItemsManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/8/25.
//

import SwiftUI

@Observable
class PinnedItemsManager {
    static let shared = PinnedItemsManager()
    static let pinnedItemsKey: String = "pinnedItems"

    private(set) var pinnedItems: [PinnedItem] = [] {
        didSet { savePinnedItems() }
    }

    var pinnedItemsByType: [PinnedItem.PinnedItemType: [PinnedItem]] {
        Dictionary(grouping: pinnedItems) { $0.type }
    }

    init() {
        getPinnedItems()
    }

    // MARK: - User Intents

    @MainActor
    func togglePinnedItem(
        itemID: String,
        courseID: String?,
        type: PinnedItem.PinnedItemType
    ) {
        guard let courseID else { return }

        if pinnedItems.contains(where: {
            $0.id == itemID && $0.courseID == courseID && $0.type == type
        }) {
            removePinnedItem(itemID: itemID, courseID: courseID, type: type)
        } else {
            addPinnedItem(itemID: itemID, courseID: courseID, type: type)
        }

        WidgetContext.shared
            .requestToRefreshWidget(widget: PinnedAnnouncementsWidget.self)
        WidgetContext.shared
            .requestToRefreshWidget(widget: PinnedFilesWidget.self)
        WidgetContext.shared
            .requestToRefreshWidget(widget: PinnedAssignmentsWidget.self)
    }

    func addPinnedItem(
        itemID: String,
        courseID: String,
        type: PinnedItem.PinnedItemType
    ) {
        let item = PinnedItem(id: itemID, courseID: courseID, type: type)
        pinnedItems.append(
            item
        )
    }

    func removePinnedItem(
        itemID: String,
        courseID: String,
        type: PinnedItem.PinnedItemType
    ) {
        let index = pinnedItems.firstIndex {
            $0.id == itemID && $0.courseID == courseID && $0.type == type
        }

        guard let index else { return }

        pinnedItems.remove(at: index)
    }

    // MARK: - Private

    private func savePinnedItems() {
        if let data = try? JSONEncoder().encode(pinnedItems) {
            UserDefaults.standard.set(data, forKey: Self.pinnedItemsKey)
        }
    }

    private func getPinnedItems() {
        var result: [PinnedItem] = []

        if let data = UserDefaults.standard.data(forKey: Self.pinnedItemsKey) {
            result = (try? JSONDecoder().decode([PinnedItem].self, from: data)) ?? []
        }

        pinnedItems = result
    }

    // MARK: - Debug
    #if DEBUG
    func clearAllPinnedItems() {
        pinnedItems.removeAll()
    }
    #endif
}

// MARK: - Type-Specific Data Sources

/// Data source for pinned announcements widget
@Observable
class PinnedAnnouncementsDataSource: ListWidgetDataSource {
    private let manager: PinnedItemsManager

    init(manager: PinnedItemsManager = .shared) {
        self.manager = manager
    }

    private var filteredItems: [PinnedItem] {
        manager.pinnedItems.filter { $0.type == .announcement }
    }

    var fetchStatus: WidgetFetchStatus {
        get {
            if filteredItems.isEmpty {
                return .loaded
            }
            let hasData = filteredItems.allSatisfy { $0.data != nil }
            return hasData ? .loaded : .loading
        }
        set { }
    }

    var widgetData: [ListWidgetData] {
        get {
            var result: [ListWidgetData] = []

            for pinnedItem in filteredItems {
                guard let data = pinnedItem.data,
                      case .announcement(let announcement) = data.modelData else { continue }

                let title = announcement.title ?? "Untitled Announcement"
                let description = data.course.name ?? "Unknown Course"

                result.append(ListWidgetData(
                    id: "\(pinnedItem.id)-\(pinnedItem.courseID)",
                    title: title,
                    description: description
                ))
            }

            return result
        }
        set { }
    }

    func fetchData(context: WidgetContext) async throws {
        await withTaskGroup(of: Void.self) { group in
            for item in filteredItems {
                group.addTask {
                    await item.itemData()
                }
            }
        }
    }

    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        guard let pinnedItem = filteredItems.first(where: {
            "\($0.id)-\($0.courseID)" == data.id
        }),
        let itemData = pinnedItem.data,
        case .announcement(let announcement) = itemData.modelData else {
            return .pinnedItems
        }

        return .announcement(announcement)
    }
}

/// Data source for pinned assignments widget
@Observable
class PinnedAssignmentsDataSource: ListWidgetDataSource {
    private let manager: PinnedItemsManager

    init(manager: PinnedItemsManager = .shared) {
        self.manager = manager
    }

    private var filteredItems: [PinnedItem] {
        manager.pinnedItems.filter { $0.type == .assignment }
    }

    var fetchStatus: WidgetFetchStatus {
        get {
            if filteredItems.isEmpty {
                return .loaded
            }
            let hasData = filteredItems.allSatisfy { $0.data != nil }
            return hasData ? .loaded : .loading
        }
        set { }
    }

    var widgetData: [ListWidgetData] {
        get {
            var result: [ListWidgetData] = []

            for pinnedItem in filteredItems {
                guard let data = pinnedItem.data,
                      case .assignment(let assignment) = data.modelData else { continue }

                let title = assignment.name
                let description = data.course.name ?? "Unknown Course"

                result.append(ListWidgetData(
                    id: "\(pinnedItem.id)-\(pinnedItem.courseID)",
                    title: title,
                    description: description
                ))
            }

            return result
        }
        set { }
    }

    func fetchData(context: WidgetContext) async throws {
        await withTaskGroup(of: Void.self) { group in
            for item in filteredItems {
                group.addTask {
                    await item.itemData()
                }
            }
        }
    }

    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        guard let pinnedItem = filteredItems.first(where: {
            "\($0.id)-\($0.courseID)" == data.id
        }),
        let itemData = pinnedItem.data,
        case .assignment(let assignment) = itemData.modelData else {
            return .pinnedItems
        }

        return .assignment(assignment)
    }
}

/// Data source for pinned files widget
@Observable
class PinnedFilesDataSource: ListWidgetDataSource {
    private let manager: PinnedItemsManager

    init(manager: PinnedItemsManager = .shared) {
        self.manager = manager
    }

    private var filteredItems: [PinnedItem] {
        manager.pinnedItems.filter { $0.type == .file }
    }

    var fetchStatus: WidgetFetchStatus {
        get {
            if filteredItems.isEmpty {
                return .loaded
            }
            let hasData = filteredItems.allSatisfy { $0.data != nil }
            return hasData ? .loaded : .loading
        }
        set { }
    }

    var widgetData: [ListWidgetData] {
        get {
            var result: [ListWidgetData] = []

            for pinnedItem in filteredItems {
                guard let data = pinnedItem.data,
                      case .file(let file) = data.modelData else { continue }

                let title = file.displayName
                let description = data.course.name ?? "Unknown Course"

                result.append(ListWidgetData(
                    id: "\(pinnedItem.id)-\(pinnedItem.courseID)",
                    title: title,
                    description: description
                ))
            }

            return result
        }
        set { }
    }

    func fetchData(context: WidgetContext) async throws {
        await withTaskGroup(of: Void.self) { group in
            for item in filteredItems {
                group.addTask {
                    await item.itemData()
                }
            }
        }
    }

    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        guard let pinnedItem = filteredItems.first(where: {
            "\($0.id)-\($0.courseID)" == data.id
        }),
        let itemData = pinnedItem.data,
        case .file(let file) = itemData.modelData else {
            return .pinnedItems
        }

        return .file(file, itemData.course.id)
    }
}
