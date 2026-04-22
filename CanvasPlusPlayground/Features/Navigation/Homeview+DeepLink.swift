//
//  Homeview+DeepLink.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/13/26.
//

import SwiftUI
import SwiftData

extension HomeView {
    func destinationForDeepLink(type: String, id: String) -> NavigationModel.Destination? {
        let context = ModelContext.shared

        switch type {
        case "course":
            guard let course = courseManager.course(withID: id) else { return nil }
            return .course(course)

        case "assignment":
            let predicate = #Predicate<Assignment> { $0.id == id }
            guard let assignment = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first else { return nil }
            return .assignment(assignment)

        case "announcement":
            let predicate = #Predicate<DiscussionTopic> { $0.id == id }
            guard let topic = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first else { return nil }
            return .announcement(topic)

        case "quiz":
            let predicate = #Predicate<Quiz> { $0.id == id }
            guard let quiz = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first else { return nil }
            return .quiz(quiz)

        case "page":
            let predicate = #Predicate<Page> { $0.id == id }
            guard let page = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first else { return nil }
            return .page(page)

        case "file":
            let predicate = #Predicate<File> { $0.id == id }
            guard let file = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first else { return nil }
            guard let folderId = file.folderId else { return nil }
            return .file(file, String(folderId))

        case "module":
            let predicate = #Predicate<Module> { $0.id == id }
            guard let module = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first,
                  let courseID = module.courseID,
                  let course = courseManager.course(withID: courseID) else { return nil }
            return .coursePage(.modules, course)

        case "person":
            let predicate = #Predicate<User> { $0.id == id }
            guard let user = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first,
                  let courseID = user.courseId,
                  let course = courseManager.course(withID: courseID) else { return nil }
            return .coursePage(.people, course)

        case "group":
            let predicate = #Predicate<CanvasGroup> { $0.id == id }
            guard let group = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first,
                  let courseId = group.courseId,
                  let course = courseManager.course(withID: String(courseId)) else { return nil }
            return .coursePage(.groups, course)

        case "todo":
            return .allToDos

        default:
            return nil
        }
    }

    @discardableResult
    func handleSpotlightDeepLink(_ identifier: String) -> Bool {
        let parts = identifier.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return false }

        let type = String(parts[0])
        let id = String(parts[1])

        guard let destination = destinationForDeepLink(type: type, id: id) else { return false }

        navigationModel.selectedTab = .dashboard
        DispatchQueue.main.async {
            navigationModel.dashboardPath.append(destination)
        }
        return true
    }

    func drainPendingSpotlightDeepLink() {
        guard let pending = pendingSpotlightIdentifier else { return }
        if handleSpotlightDeepLink(pending) {
            pendingSpotlightIdentifier = nil
        }
    }
}
