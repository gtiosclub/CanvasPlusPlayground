//
//  OpenInWebButton.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 4/9/25.
//

import SwiftUI

private struct OpenInCanvasWebButton: View {
    let path: WebButtonType
    
    var body: some View {
        Link(destination: path.url) {
            // For some reason, when I use a label, the button looks weird with liquid glass. Using a button looks correct
            Button("Open in web", systemImage: "globe", action: {})
        }
        .environment(\.openURL, OpenURLAction { url in
            return .systemAction
        })
    }
}

private struct OpenInCanvasWebButtonModifier: ViewModifier {
    let path: WebButtonType
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem {
                    OpenInCanvasWebButton(path: path)
                }
            }
    }
}

extension View {
    func openInCanvasWebToolbarButton(_ type: WebButtonType) -> some View {
        self.modifier(OpenInCanvasWebButtonModifier(path: type))
    }
}

enum WebButtonType {
    case homepage(String)
    case grades(String)
    case files(String)
    case quizzes(String)
    case announcement(String, String)
    case assignment(String, String)
    
    var urlString: String {
        CanvasService.canvasURL + {
            switch self {
            case .homepage(let courseID):
                "courses/\(courseID)/"
            case .grades(let courseID):
                "courses/\(courseID)/grades"
            case .files(let courseID):
                "courses/\(courseID)/files"
            case .quizzes(let courseID):
                "courses/\(courseID)/quizzes"
            case .announcement(let courseID, let announcementID):
                "courses/\(courseID)/discussion_topics/\(announcementID)"
            case .assignment(let courseID, let assignmentID):
                "courses/\(courseID)/assignments/\(assignmentID)"
            }
        }()
    }
    
    var url: URL {
        URL(string: urlString) ?? URL(string: CanvasService.canvasURL)!
    }
}
