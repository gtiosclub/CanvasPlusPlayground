//
//  OpenInWebButton.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 4/9/25.
//

import SwiftUI

//FIXME: removed private to test in other modules
struct OpenInCanvasButton: View {
    var titleText: String {
        #if os(iOS)
        "Open in Canvas Student"
        #else
        "Open in web"
        #endif
    }

    let path: CanvasButtonType
    @Environment(\.openURL) var openURL

    var body: some View {
        Button(titleText, systemImage: "globe") {
            print("opening url \(path.url)")
            openURL(path.url)
        }
    }
}

private struct OpenInCanvasButtonModifier: ViewModifier {
    let path: CanvasButtonType
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem {
                    OpenInCanvasButton(path: path)
                }
            }
    }
}

extension View {
    func openInCanvasToolbarButton(_ type: CanvasButtonType) -> some View {
        self.modifier(OpenInCanvasButtonModifier(path: type))
            .environment(\.openURL, OpenURLAction { _ in
                .systemAction
            })
    }
}

enum CanvasButtonType {
    case homepage(String)
    case grades(String)
    case files(String)
    case quizzes(String, String)
    case announcement(String, String)
    case assignment(String, String)

    var canvasPath: String {
        #if os(iOS)
        guard let url = URL(string: CanvasService.canvasSystemURL),
              UIApplication.shared.canOpenURL(url) else {
            return CanvasService.canvasWebURL
        }
        return CanvasService.canvasSystemURL + CanvasService.canvasDomain
        #else
        return CanvasService.canvasWebURL
        #endif
    }

    var urlString: String {
        canvasPath + {
            switch self {
            case .homepage(let courseID):
                "courses/\(courseID)/"
            case .grades(let courseID):
                "courses/\(courseID)/grades"
            case .files(let courseID):
                "courses/\(courseID)/files"
            case .quizzes(let courseID, let quizID):
                "courses/\(courseID)/quizzes/\(quizID)"
            case .announcement(let courseID, let announcementID):
                "courses/\(courseID)/discussion_topics/\(announcementID)"
            case .assignment(let courseID, let assignmentID):
                "courses/\(courseID)/assignments/\(assignmentID)"
            }
        }()
    }

    var url: URL {
        URL(string: urlString) ?? URL(string: CanvasService.canvasWebURL)!
    }
}
