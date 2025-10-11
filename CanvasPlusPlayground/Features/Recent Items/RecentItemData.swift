//
//  RecentItemData.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import Foundation

enum RecentItemData {
    case announcement(DiscussionTopic)
    case assignment(Assignment)
    case file(File)
    case quiz(Quiz)
}

extension RecentItem {
    func fetchData() async throws {
        switch type {
        case .announcement:
            let announcements = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getDiscussionTopics(courseId: courseID)
            ) { cachedAnnouncements in
                guard let announcement = cachedAnnouncements?.first(where: { $0.id == self.id }) else { return }
                self.data = .announcement(announcement)
            }

            guard let announcement = announcements.first(where: { $0.id == id }) else {
                throw RecentItemError.itemNotFound
            }
            self.data = .announcement(announcement)

        case .assignment:
            let assignments = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getAssignment(id: id, courseId: courseID)
            ) { cachedAssignments in
                guard let assignment = cachedAssignments?.first else { return }
                self.data = .assignment(assignment)
            }

            guard let assignment = assignments.first else {
                throw RecentItemError.itemNotFound
            }
            self.data = .assignment(assignment)

        case .file:
            let files = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getFile(fileId: id)
            ) { cachedFiles in
                guard let file = cachedFiles?.first else { return }
                self.data = .file(file)
            }

            guard let file = files.first else {
                throw RecentItemError.itemNotFound
            }
            self.data = .file(file)

        case .quiz:
            let quizzes = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getQuiz(id: id, courseId: courseID)
            ) { cachedQuizzes in
                guard let quiz = cachedQuizzes?.first else { return }
                self.data = .quiz(quiz)
            }

            guard let quiz = quizzes.first else {
                throw RecentItemError.itemNotFound
            }
            self.data = .quiz(quiz)
        }
    }

    var navigationDestination: NavigationModel.Destination? {
        guard let data else { return nil }

        switch data {
        case .announcement(let announcement):
            return .announcement(announcement)
        case .assignment(let assignment):
            return .assignment(assignment)
        case .file(let file):
            return .file(file, courseID)
        case .quiz(let quiz):
            return .quiz(quiz)
        }
    }
}

enum RecentItemError: Error {
    case itemNotFound
    case fetchFailed
}
