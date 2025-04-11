//
//  CanvasURLService.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 4/8/25.
//

import Foundation

enum CanvasURLService {
    enum URLServiceResult {
        case announcement(DiscussionTopic.ID)
        case assignment(Assignment.ID)
        case file(File.ID)
        case page(Page.ID)
        // TODO: Add items as needed.

        init?(pathType: String, id: String) {
            switch pathType {
            case "assignments":
                self = .assignment(id)
            case "discussion_topics", "announcements":
                self = .announcement(id)
            case "pages":
                self = .page(id)
            case "files":
                self = .file(id)
            default:
                return nil
            }
        }
    }

    static func determineNavigationDestination(from url: URL) -> URLServiceResult? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        // Example URL: "https://gatech.instructure.com/courses/447818/assignments/2053294"

        // Break down URL into ["courses", courseID, type, objectID]

        guard let path = components?.path else { return nil }
        let pathComponents = path.components(separatedBy: "/").filter { !$0.isEmpty }

        guard pathComponents.count >= 4 else { return nil }

        let type = pathComponents[2] // (assignments, files, etc)
        let id = pathComponents[3]

        return .init(pathType: type, id: id)
    }
}

extension NavigationModel {
    func handleURLSelection(result: CanvasURLService.URLServiceResult, courseID: Course.ID?) async {
        guard let courseID else { return }

        guard let destination = await Self.Destination.destination(
            from: result,
            for: courseID
        ) else { return }

        navigationPath.append(destination)
    }
}

extension NavigationModel.Destination {
    static func destination(from urlServiceResult: CanvasURLService.URLServiceResult, for courseID: Course.ID) async -> Self? {
        switch urlServiceResult {
        case .announcement(let id):
            var announcement: DiscussionTopic?

            let announcements = try? await CanvasService.shared.loadAndSync(
                CanvasRequest
                    .getSingleDiscussionTopic(courseId: courseID, topicId: id),
                onCacheReceive: { cachedAnnouncements in
                    announcement = cachedAnnouncements?.first
                }
            )

            if let announcements, !announcements.isEmpty {
                announcement = announcements.first
            }

            guard let announcement else { return nil }

            return .announcement(announcement)
        case .assignment(let id):
            var assignment: Assignment?

            let assignments = try? await CanvasService.shared.loadAndSync(
                CanvasRequest.getAssignment(id: id, courseId: courseID),
                onCacheReceive: { cachedAssignments in
                    assignment = cachedAssignments?.first
                }
            )

            if let assignments, !assignments.isEmpty {
                assignment = assignments.first
            }

            guard let assignment else { return nil }

            return .assignment(assignment)
        case .page(let id):
            var page: Page?

            let pages = try? await CanvasService.shared.loadAndSync(
                CanvasRequest.getSinglePage(courseId: courseID, pageURL: id),
                onCacheReceive: { cachedPages in
                    page = cachedPages?.first
                }
            )

            if let pages, !pages.isEmpty {
                page = pages.first
            }

            guard let page else {
                return nil
            }

            return .page(page)
        case .file(let id):
            var file: File?

            let files = try? await CanvasService.shared.loadAndSync(
                CanvasRequest.getFile(fileId: id),
                onCacheReceive: { cachedFiles in
                    file = cachedFiles?.first
                }
            )

            if let files, !files.isEmpty {
                file = files.first
            }

            guard let file else {
                return nil
            }

            return .file(file, courseID)
        }
    }
}
