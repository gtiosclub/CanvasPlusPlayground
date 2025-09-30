//
//  CanvasURLService+Modules.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/2/25.
//

extension CanvasURLService.URLServiceResult {
    init?(from moduleType: ModuleItemType) {
        switch moduleType {
        case .assignment(id: let id):
            self.init(pathType: "assignments", id: id)
        case .file(id: let id):
            self.init(pathType: "files", id: id)
        case .discussion(id: let id):
            self.init(pathType: "discussion_topics", id: id)
        case .quiz(id: let id):
            self.init(pathType: "quizzes", id: id)
        case .externalURL:
            return nil // FIXME: Implement
        case .externalTool:
            return nil // FIXME: Implement
        case .page(id: let id):
            self.init(pathType: "pages", id: id)
        case .subHeader:
            return nil
        }
    }

    var systemImageName: String {
        switch self {
        case .announcement:
            NavigationModel.CoursePage.announcements.systemImageIcon
        case .assignment:
            NavigationModel.CoursePage.assignments.systemImageIcon
        case .file:
            .document
        case .page:
            NavigationModel.CoursePage.pages.systemImageIcon
        }
    }
}
