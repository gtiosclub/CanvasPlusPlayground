//
//  PinnedItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/9/25.
//

import Foundation

@Observable
class PinnedItem: Identifiable, Codable, Equatable {

    let id: String
    let courseID: String
    let type: PinnedItemType
    var data: PinnedItemData?

    enum PinnedItemType: Int, Codable {
        case announcement, assignment, file
        // TODO: Add more pinned item types

        var displayName: String {
            switch self {
            case .announcement: "Announcements"
            case .assignment: "Assignments"
            case .file: "Files"
            }
        }
    }

    func itemData() async {
        do {
            async let modelData = try fetchData()
            async let course = try CanvasService.shared.loadAndSync(
                CanvasRequest.getCourse(id: courseID)
            )

            self.data =  .init(
                modelData: try await modelData,
                course: try await course.first
            )
            print("Caching pinnedItem data \(self.data)")
        } catch {
            print("Error fetching \(type): \(error.localizedDescription)")
        }
    }

    private func fetchData() async throws -> PinnedItemData.ModelData? {
        switch type {
        case .announcement:
            let announcements = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getDiscussionTopics(courseId: courseID)
            )
            guard let announcement = announcements.first(where: { $0.id == id }) else { return nil }
            return .announcement(announcement)

        case .assignment:
            let assignments = try await CanvasService.shared.loadAndSync(
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

    enum CodingKeys: String, CodingKey {
        case id
        case courseID
        case type
    }

    init(id: String, courseID: String, type: PinnedItemType, data: PinnedItemData? = nil) {
        self.id = id
        self.courseID = courseID
        self.type = type
        self.data = data
    }

    static func == (lhs: PinnedItem, rhs: PinnedItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct PinnedItemData {
    enum ModelData {
        case announcement(DiscussionTopic)
        case assignment(Assignment)
        case file(File)
        // TODO: Add more pinned item types
    }

    let modelData: ModelData
    let course: Course

    init?(modelData: ModelData?, course: Course?) {
        guard let modelData, let course else { return nil }

        self.modelData = modelData
        self.course = course
    }
}
