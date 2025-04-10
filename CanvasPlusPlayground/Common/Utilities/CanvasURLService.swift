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

        init?(pathType: String, id: String) {
            switch pathType {
            case "assignments":
                self = .assignment(id)
            case "discussion_topics", "announcements":
                self = .announcement(id)
            case "pages":
                self = .page(id)
            case "files":
                // TODO: Support Files
                return nil
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
            let announcements = try? await CanvasService.shared.loadAndSync(
                CanvasRequest
                    .getSingleDiscussionTopic(courseId: courseID, topicId: id)
            )

            guard let announcement = announcements?.first else { return nil }

            return .announcement(announcement)
        case .assignment(let id):
            let assignments = try? await CanvasService.shared.loadAndSync(
                CanvasRequest.getAssignment(id: id, courseId: courseID)
            )

            guard let assignment = assignments?.first else { return nil }

            return .assignment(assignment)
        case .page(let id):
            let pages = try? await CanvasService.shared.loadAndSync(
                CanvasRequest.getSinglePage(courseId: courseID, pageURL: id)
            )

            guard let page = pages?.first else {
                return nil
            }

            return .page(page)
        case .file:
            // TODO: Support Files
            return nil
        }
    }
}
