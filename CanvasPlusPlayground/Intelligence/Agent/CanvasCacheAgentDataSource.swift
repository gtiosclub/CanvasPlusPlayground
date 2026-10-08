//
//  CanvasCacheAgentDataSource.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation

/// The app's `AgentDataSource`. Reads go to the local cache first through
/// `CanvasService.load`, and only hit the network (`syncWithAPI`) when nothing is cached,
/// so tools are fast and work offline. Sandbox mode uses `SandboxData`, like the managers do.
@MainActor
final class CanvasCacheAgentDataSource: AgentDataSource {
    private let courseManager: CourseManager

    init(courseManager: CourseManager) {
        self.courseManager = courseManager
    }

    func courses() async throws -> [Evidence] {
        let courses = AppEnvironment.isSandbox ? SandboxData.dummyCourses : courseManager.activeCourses
        return courses.map { $0.evidence }
    }

    func assignments(courseID: String) async throws -> [Evidence] {
        let courseName = courseName(for: courseID)

        if AppEnvironment.isSandbox {
            return SandboxData.dummyAssignmentGroups(forCourseID: courseID)
                .flatMap { $0.assignments ?? [] }
                .map { $0.createModel().evidence(courseID: courseID, courseName: courseName) }
        }

        let assignments: [Assignment] = try await cacheFirst(CanvasRequest.getAssignments(courseId: courseID))
        return assignments.map { $0.evidence(courseID: courseID, courseName: courseName) }
    }

    func announcements(courseID: String) async throws -> [Evidence] {
        let courseName = courseName(for: courseID)

        let announcements: [DiscussionTopic] = if AppEnvironment.isSandbox {
            SandboxData.dummyAnnouncements(forCourseID: courseID)
        } else {
            try await cacheFirst(
                CanvasRequest.getDiscussionTopics(courseId: courseID, onlyAnnouncements: true)
            )
        }

        return announcements.map { $0.evidence(courseID: courseID, courseName: courseName) }
    }

    /// Calendar events aren't cached; they come straight from the course's ICS feed.
    func calendarEvents(courseID: String) async throws -> [Evidence] {
        guard !AppEnvironment.isSandbox,
              let course = course(for: courseID),
              let icsURL = URL(string: course.calendarIcs ?? "") else {
            return []
        }

        return try await ICSParser.fetchEvents(from: icsURL, for: course)
            .flatMap(\.events)
            .map { $0.evidence(courseID: courseID, courseName: course.displayName) }
    }

    func toDos() async throws -> [Evidence] {
        guard !AppEnvironment.isSandbox else { return [] }

        let toDos: [ToDoItem] = try await cacheFirst(CanvasRequest.getToDoItems(include: [.ungradedQuizzes]))
        return toDos.map { toDo in
            toDo.evidence(courseName: course(for: toDo.courseID.asString)?.displayName ?? toDo.contextName)
        }
    }

    func files(courseID: String) async throws -> [Evidence] {
        let files: [File] = if AppEnvironment.isSandbox {
            SandboxData.dummyFiles(forCourseID: courseID)
        } else {
            try await cacheFirst(CanvasRequest.getAllFilesInCourse(courseId: courseID))
        }

        return files.map { $0.evidence(courseID: courseID, courseName: courseName(for: courseID)) }
    }

    // MARK: - Helpers

    private func course(for courseID: String) -> Course? {
        let courses = AppEnvironment.isSandbox ? SandboxData.dummyCourses : courseManager.activeCourses
        return courses.first { $0.id == courseID }
    }

    private func courseName(for courseID: String) -> String? {
        course(for: courseID)?.displayName
    }

    /// Cached models if there are any, otherwise a network sync.
    private func cacheFirst<Request: CacheableAPIRequest>(
        _ request: Request
    ) async throws -> [Request.PersistedModel] {
        if let cached = try await CanvasService.shared.load(request), !cached.isEmpty {
            return cached
        }

        return try await CanvasService.shared.syncWithAPI(request)
    }
}

// MARK: - Evidence from Canvas models

extension Course {
    var evidence: Evidence {
        Evidence(
            ref: .course(id: id),
            title: displayName,
            snippet: [courseCode, term?.name].compactMap { $0 }.joined(separator: " · "),
            facts: EvidenceFacts(courseName: displayName)
        )
    }
}

extension Assignment {
    func evidence(courseID: String, courseName: String?) -> Evidence {
        Evidence(
            ref: .assignment(id: id, courseID: courseID),
            title: name,
            snippet: assignmentDescription,
            facts: EvidenceFacts(
                courseName: courseName,
                // `dueDate` falls back to a placeholder when `dueAt` is missing; never pass that on as a fact.
                dueDate: dueAt == nil ? nil : dueDate,
                pointsPossible: pointsPossible,
                score: submission?.score
            )
        )
    }
}

extension DiscussionTopic {
    func evidence(courseID: String, courseName: String?) -> Evidence {
        Evidence(
            ref: .announcement(id: id, courseID: courseID),
            title: title ?? "Untitled announcement",
            snippet: message,
            facts: EvidenceFacts(courseName: courseName, postedAt: postedAt ?? createdAt)
        )
    }
}

extension CanvasCalendarEvent {
    func evidence(courseID: String, courseName: String?) -> Evidence {
        // The ICS parser uses "-" when an event has no location.
        let location = location == "-" || location.isEmpty ? nil : location

        return Evidence(
            ref: .calendarEvent(uid: id, courseID: courseID),
            title: summary,
            snippet: location,
            facts: EvidenceFacts(
                courseName: courseName,
                startDate: startDate,
                endDate: endDate,
                location: location
            )
        )
    }
}

extension ToDoItem {
    func evidence(courseName: String?) -> Evidence {
        // Same placeholder problem as `Assignment.dueDate`: only trust a due date that was set.
        let realDueDate: Date? = if let assignmentAPI {
            assignmentAPI.due_at == nil ? nil : assignmentAPI.dueDate
        } else {
            dueDate
        }

        return Evidence(
            ref: .toDo(id: id, courseID: courseID.asString),
            title: title,
            snippet: assignmentAPI?.description ?? quizAPI?.description,
            facts: EvidenceFacts(
                courseName: courseName,
                dueDate: realDueDate,
                pointsPossible: assignmentAPI?.points_possible
            )
        )
    }
}

extension File {
    func evidence(courseID: String, courseName: String?) -> Evidence {
        let details = [
            contentType,
            size.map { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file) }
        ]

        return Evidence(
            ref: .file(id: id, courseID: courseID),
            title: displayName,
            snippet: details.compactMap { $0 }.joined(separator: " · "),
            facts: EvidenceFacts(courseName: courseName, postedAt: updatedAt ?? createdAt)
        )
    }
}
