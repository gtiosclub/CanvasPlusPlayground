//
//  PinnedItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/9/25.
//

import Foundation

@Observable
class PinnedItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let courseID: String
    let type: PinnedItemType
    var data: PinnedItemData?

    private var course: Course?
    private var modelData: PinnedItemData.ModelData?

    enum PinnedItemType: Int, Codable {
        case announcement, assignment, file
        // TODO: Add more pinned item types

        var displayName: String {
            switch self {
            case .announcement:
                "Announcements"
            case .assignment:
                "Assignments"
            case .file:
                "Files"
            }
        }
    }

    func itemData() async {
        do {

            async let fetchData: Void = fetchData()
            // TODO: use new course infra
            async let fetchCourse: [Course] = CanvasService.shared.loadAndSync(
                CanvasRequest.getCourse(id: courseID)
            ) { cachedCourse in
                    guard let course = cachedCourse?.first else { return }
                    setData(course: course)
            }

            try await (_, _) = (fetchData, fetchCourse)
        } catch {
            LoggerService.main.error("Error fetching \(self.type.displayName)")
        }
    }

    private func fetchData() async throws {
        switch type {
        case .announcement:
            let announcements = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getDiscussionTopics(courseId: courseID)
            ) { cachedAnnouncements in
                    guard let announcement = cachedAnnouncements?.first(where: { $0.id == id }) else { return }
                    setData(modelData: .announcement(announcement))
            }
            guard let announcement = announcements.first(where: { $0.id == id }) else { return }
            setData(modelData: .announcement(announcement))
        case .assignment:
            let assignments = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getAssignment(id: id, courseId: courseID)
            ) { cachedAssignments in
                    guard let assignment = cachedAssignments?.first else { return }
                    setData(modelData: .assignment(assignment))
            }
            guard let assignment = assignments.first else { return }
            setData(modelData: .assignment(assignment))

        case .file:
            let files = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getFile(fileId: id)
            ) { cachedFiles in
                    guard let file = cachedFiles?.first else { return }
                    setData(modelData: .file(file))
            }
            guard let file = files.first else { return }
            setData(modelData: .file(file))
        }
    }

    func setData(course: Course? = nil, modelData: PinnedItemData.ModelData? = nil) {
        if course != nil {
            self.course = course
        }

        if modelData != nil {
            self.modelData = modelData
        }

        if self.course != nil && self.modelData != nil {
            self.data = .init(modelData: self.modelData, course: self.course)
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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
