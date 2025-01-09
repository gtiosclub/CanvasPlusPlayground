//
//  PinnedItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/9/25.
//

import Foundation

struct PinnedItem: Identifiable, Codable {
    let id: String
    let courseID: String
    let type: PinnedItemType

    enum PinnedItemType: String, Codable {
        case announcement, assignment, file
        // TODO: Add more pinned item types
    }

    func itemData() async -> PinnedItemData? {
        do {
            return try await fetchData()
        } catch {
            print("Error fetching \(type): \(error.localizedDescription)")
            return nil
        }
    }

    private func fetchData() async throws -> PinnedItemData? {
        switch type {
        case .announcement:
            let announcements = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getAnnouncements(courseId: courseID)
            )
            guard let announcement = announcements.first(where: { $0.id == id }) else { return nil }
            return .announcement(announcement)

        case .assignment:
            let assignments = try await CanvasService.shared.fetch(
                CanvasRequest.getAssignment(id: id, courseId: courseID)
            )
            guard let assignment = assignments.first else { return nil }
            return .assignment(assignment)

        case .file:
            let files = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getFile(fileId: id)
            )
            guard let file = files.first else { return nil }
            return .file(file)
        }
    }
}

enum PinnedItemData {
    case announcement(Announcement)
    case assignment(AssignmentAPI)
    case file(File)
    // TODO: Add more pinned item types
}
