//
//  PinnedAssignmentsDataSource.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/18/25.
//

import SwiftUI

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
