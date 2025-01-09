//
//  PinnedItemsManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/8/25.
//

import SwiftUI

struct PinnedItem: Identifiable, Codable {
    let id: String
    let courseID: String
    let type: PinnedItemType

    enum PinnedItemType: String, Codable {
        case announcement, assignment, file
    }

    func itemData() async -> PinnedItemData? {
        do {
            switch type {
            case .announcement:
                let announcements = try await CanvasService.shared.loadAndSync(
                    CanvasRequest.getAnnouncements(courseId: courseID)
                )
                if let announcement = announcements.first(where: { $0.id == id }) {
                    return .announcement(announcement)
                }
            case .assignment:
                if let assignment = try await CanvasService.shared.fetch(
                    CanvasRequest.getAssignment(id: id, courseId: courseID)
                ).first {
                    return .assignment(assignment)
                }
            case .file:
                if let file = try await CanvasService.shared.loadAndSync(
                    CanvasRequest.getFile(fileId: id)
                ).first {
                    return .file(file)
                }
            }
        } catch {
            print("Error fetching \(type): \(error.localizedDescription)")
        }

        return nil
    }
}

enum PinnedItemData {
    case announcement(Announcement)
    case assignment(AssignmentAPI)
    case file(File)
}

@Observable
class PinnedItemsManager {
    private(set) var pinnedItems: [PinnedItem] {
        get {
            access(keyPath: \.pinnedItems)

            if let data = UserDefaults.standard.data(forKey: "pinnedItems") {
                return (try? JSONDecoder().decode([PinnedItem].self, from: data)) ?? []
            }

            return []
        }
        set {
            access(keyPath: \.pinnedItems)

            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "pinnedItems")
            }
        }
    }

    func togglePinnedItem(
        itemID: String,
        courseID: String,
        type: PinnedItem.PinnedItemType
    ) {
        if pinnedItems.contains(where: {
            $0.id == itemID && $0.courseID == courseID && $0.type == type
        }) {
            removePinnedItem(itemID: itemID, courseID: courseID, type: type)
        } else {
            addPinnedItem(itemID: itemID, courseID: courseID, type: type)
        }
    }

    func addPinnedItem(
        itemID: String,
        courseID: String,
        type: PinnedItem.PinnedItemType
    ) {
        pinnedItems.append(
            PinnedItem(id: itemID, courseID: courseID, type: type)
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
}
