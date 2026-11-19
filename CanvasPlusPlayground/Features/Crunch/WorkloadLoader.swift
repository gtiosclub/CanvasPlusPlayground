//
//  WorkloadLoader.swift
//  CanvasPlusPlayground
//

import Foundation

/// Gathers upcoming work for the workload curve: assignments and quizzes from each course's
/// assignment groups (which carry the group weights), plus exams and other events from the
/// course calendar feeds. Reads the local cache first, like the agent tools.
@MainActor
struct WorkloadLoader {
    let courseManager: CourseManager

    /// Statuses that mean there's nothing left to do.
    static let finished: Set<SubmissionStatus> = [.submitted, .late, .graded, .excused]

    func items(from start: Date, days: Int = WorkloadCurve.defaultDays) async -> [WorkloadItem] {
        let courses = AppEnvironment.isSandbox ? SandboxData.dummyCourses : courseManager.activeCourses
        let end = Calendar.current.date(byAdding: .day, value: days + 7, to: start) ?? start
        var items: [WorkloadItem] = []

        for course in courses {
            items += await assignmentItems(for: course)
            items += await eventItems(for: course)
        }

        // Keep anything whose lead-up overlaps the window.
        let windowStart = Calendar.current.startOfDay(for: start)
        return items.filter { $0.date >= windowStart && $0.date < end }
    }

    private func assignmentItems(for course: Course) async -> [WorkloadItem] {
        let groups: [AssignmentGroup]
        if AppEnvironment.isSandbox {
            groups = SandboxData.dummyAssignmentGroups(forCourseID: course.id)
        } else {
            let request = CanvasRequest.getAssignmentGroups(courseId: course.id)
            if let cached = try? await CanvasService.shared.load(request), !cached.isEmpty {
                groups = cached
            } else {
                groups = (try? await CanvasService.shared.syncWithAPI(request)) ?? []
            }
        }

        return groups.flatMap { group in
            let assignments = group.assignments ?? []
            let groupPoints = assignments.compactMap(\.points_possible).reduce(0, +)

            return assignments.compactMap { api -> WorkloadItem? in
                let assignment = api.createModel()
                guard assignment.dueAt != nil else { return nil }

                let evidence = assignment.evidence(courseID: course.id, courseName: course.displayName)
                if let status = evidence.facts.submissionStatus, Self.finished.contains(status) { return nil }
                guard let due = evidence.facts.dueDate else { return nil }

                let isQuiz = api.submission_types?.contains("online_quiz") == true
                return WorkloadItem(
                    id: evidence.id,
                    title: assignment.name,
                    courseName: course.displayName,
                    kind: WorkloadItem.kind(forTitle: assignment.name, default: isQuiz ? .quiz : .assignment),
                    date: due,
                    pointsPossible: assignment.pointsPossible,
                    groupWeight: group.groupWeight,
                    groupPoints: groupPoints > 0 ? groupPoints : nil,
                    evidence: evidence
                )
            }
        }
    }

    private func eventItems(for course: Course) async -> [WorkloadItem] {
        guard !AppEnvironment.isSandbox, let url = URL(string: course.calendarIcs ?? "") else { return [] }
        let groups = (try? await ICSParser.fetchEvents(from: url, for: course)) ?? []

        return groups.flatMap(\.events).map { event in
            let evidence = event.evidence(courseID: course.id, courseName: course.displayName)
            return WorkloadItem(
                id: evidence.id,
                title: event.summary,
                courseName: course.displayName,
                kind: WorkloadItem.kind(forTitle: event.summary, default: .event),
                date: event.startDate,
                evidence: evidence
            )
        }
    }
}
